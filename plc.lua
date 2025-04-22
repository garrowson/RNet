-- 
--  PLC - Programmable Logic Controller, acts as sensor and actuator
--
local comms = require("common/comms")
local log = require("common/log")

local VERSION = "0.2.0"

local RNET_CHANNEL = settings.get("rnet.channel")
local SUPERVISOR_ADR = settings.get("rnet.supervisor")

local PROTOCOL = comms.PROTOCOL

local pModem = nil ---@type Modem
local managedPeripherals = nil ---@type ManagedPeripherals
local ignoredPeripherals = "modem,drive,"


function ManagedPeripherals()
    local self = {
        peripherals = {},
        count = 0
    }

    ---@class ManagedPeripherals
    local public = {}

    ---comment
    ---@param p any
    ---@param getDataFunction function
    function public.addPeripheral(p, getDataFunction)
        local name = peripheral.getName(p)
        local value = {}
        value.peripheral = p
        value.getData = getDataFunction

        self.peripherals[name] = value
        self.count = self.count + 1
    end

    --- Get peripheral
    --- @param name string
    --- @return any
    function public.getPeripheral(name)
        if self.peripherals[name] then
            return self.peripherals[name].peripheral
        else
            return nil
        end
    end

    ---Get data from peripheral using the registered function
    ---@param name string
    ---@return table
    function public.getPeripheralData(name)
        if self.peripherals[name] then
            return self.peripherals[name].getData()
        else
            return {}
        end
    end


     ---Get count of managed peripherals
     ---@return integer
    function public.getCount() return self.count end

    return public
end




local function setup()
    term.clear()
    term.setCursorPos(1, 1)
    log.init("/log.txt", log.MODE.NEW, true)
    log.info("RNet PLC " .. VERSION)
    term.write("RNet PLC " .. VERSION .. " started\n")
    log.info("COMMS " .. comms.VERSION .. " loaded")

    pModem = peripheral.find("modem") ---@diagnostic disable-line
    if not pModem then error("No modem found") end
    pModem.open(RNET_CHANNEL)

    log.info("Modem opened on channel " .. RNET_CHANNEL)
    log.info("Supervisor address: " .. SUPERVISOR_ADR)
    log.info("Loading peripherals...")

    managedPeripherals = ManagedPeripherals()

    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        local peripheralType = peripheral.getType(name)
        local device = peripheral.wrap(name) ---@type any

        if peripheralType == "energyDetector" then
            local getDataFunction = function() return device.getTransferRate() end
            managedPeripherals.addPeripheral(device, getDataFunction)
            log.info("Added energyDetector " .. name)

        elseif string.find(ignoredPeripherals, peripheralType .. ",") then
            log.debug("Ignoring " .. peripheralType .. " " .. name)
        else
            log.debug(peripheralType .. " is not supported")
        end
    end
    log.info("Loaded " .. managedPeripherals.getCount() .. " peripherals")




    log.info("entering main loop")
end


local function main()
    local event = { os.pullEvent() }

    if event[1] == "modem_message" then
        local side, channel, replyChannel, message = event[2], event[3], event[4], event[5]
        local net_packet = comms.net_packet()
        net_packet.receive(message)

        if net_packet.is_valid() then
            if net_packet.protocol() == PROTOCOL.PERIPHERALDATA then
                local periph_pckt = comms.peripheraldata_packet()
                local valid = periph_pckt.decode(net_packet)

                if valid then
                    local peripheralName = periph_pckt.get_peripheralName()
                    
                    if managedPeripherals.getPeripheral(peripheralName) == -1 then
                        log.info(peripheralName .. " requested, but not known")
                    else
                        local data = managedPeripherals.getPeripheralData(peripheralName)
                        local net_pkt = comms.net_packet()
                        net_pkt.make(SUPERVISOR_ADR, PROTOCOL.PERIPHERALDATA, data)
                        pModem.transmit(RNET_CHANNEL, RNET_CHANNEL, net_pkt.raw_sendable())
                        log.info("Data sent for " .. peripheralName)

                    end
                end
            
            end
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