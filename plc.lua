-- 
--  PLC - Programmable Logic Controller, acts as sensor and actuator
--
local comms = require("common/comms")
local log = require("common/log")

local RNET_CHANNEL = settings.get("rnet.channel")
local SUPERVISOR_ADR = settings.get("rnet.supervisor")

local PROTOCOL = comms.PROTOCOL


local pModem = nil ---@type Modem


local energyDetectors = {}

local function advertise_EnergyDetectors()
    log.dmesg("Advertising " .. #energyDetectors .. " energy detectors")
    local names = {}
    local ids = {}

    for i = 1, #energyDetectors do
        table.insert(names, energyDetectors[i].name)
        table.insert(ids, i)
    end

    local net_pkt = comms.net_packet()
    local adv_pkt = comms.advertise_packet()

    adv_pkt.make("energyDetector", names, ids, #energyDetectors)
    net_pkt.make(SUPERVISOR_ADR, PROTOCOL.ADVERTISE, adv_pkt.raw_sendable())

    pModem.transmit(RNET_CHANNEL, RNET_CHANNEL, net_pkt.raw_sendable())
end

---comment
---@param names table Names of the energy detectors
---@param ids table Ids of the energy detectors
---@return table ratesForNamed Rates for named energy detectors
---@return table ratesForIds Rates for id energy detectors
local function getTransferRates(names, ids)
    local ratesForNamed = {}
    local ratesForIds = {}

    for i = 1, #names do
        for j = 1, #energyDetectors do
            if names[i] == energyDetectors[j].name then
                local rate = energyDetectors[j].peripheral.getTransferRate()
                table.insert(ratesForNamed, rate)
                break
            end
        end
    end

    for i = 1, #ids do
        table.insert(ratesForIds, energyDetectors[ids[i]].peripheral.getTransferRate())
    end

    return ratesForNamed, ratesForIds
end

local function setup()
    term.clear()
    term.setCursorPos(1, 1)
    log.init("/log.txt", log.MODE.NEW, true)

    ---@diagnostic disable
    pModem = peripheral.find("modem")
    local pEnergyDetectors = { peripheral.find("energyDetector") }
    ---@diagnostic enable

    if not pModem then error("No modem found") end

    pModem.open(RNET_CHANNEL)

    energyDetectors = {}
    if #pEnergyDetectors > 0 then
        for i = 1, #pEnergyDetectors do
            local kv = {}
            kv.name = pEnergyDetectors[i].getName()
            kv.peripheral = pEnergyDetectors[i]
            table.insert(energyDetectors, kv)
        end

        advertise_EnergyDetectors()
    end
end


local function main()
    local timer = os.startTimer(1)
    local event = { os.pullEvent() }

    if event[1] == "modem_message" then
        local side, channel, replyChannel, message = event[2], event[3], event[4], event[5]
        local net_packet = comms.net_packet()
        net_packet.receive(message)

        if net_packet.is_valid() then
            if net_packet.protocol() == PROTOCOL.REQUEST_TRANSFERRATE then
                local req_tfrate = comms.req_transferrate_packet()
                local valid = req_tfrate.decode(net_packet)

                if valid then
                    log.dmesg("TRANSFERRATEs requested")
                    local ratesForNamed, ratesForIds = getTransferRates(req_tfrate.get_peripheralNames(), req_tfrate.get_peripheralIds())

                    local net_pkt = comms.net_packet()
                    local tfraterply_pkt = comms.req_transferrate_reply_packet()
                    tfraterply_pkt.make(ratesForNamed, ratesForIds)
                    net_pkt.make(SUPERVISOR_ADR, PROTOCOL.REQUEST_TRANSFERRATE_REPLY, tfraterply_pkt.raw_sendable())
                    pModem.transmit(RNET_CHANNEL, RNET_CHANNEL, net_pkt.raw_sendable())
                end
                
            end
        end

    elseif event[1] == "timer" then
        if event[2] == timer then
            

            timer = os.startTimer(1)
        end
    end
end

setup()
while true do
    local success, result = pcall(main)
    if not success then
        print("\nError: " .. result)
        print("Press Strg+T to terminate autostart...")
        os.sleep(3)
    
    elseif result=="reload" then    -- ToDo: Status flag and actual reload functionality
        print("Reloading PLC...")
        setup()
    end
end