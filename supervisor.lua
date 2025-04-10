-- 
--  Supervisor - Monitors PLCs
--
-- 
--  PLC - Programmable Logic Controller, acts as sensor and actuator
--
local comms = require("common/comms")
local log = require("common/log")

local RNET_CHANNEL = settings.get("rnet.channel")

local PROTOCOL = comms.PROTOCOL


local pModem = nil ---@type Modem


local function setup()
    log.init("/log.txt", log.MODE.NEW, true, peripheral.find("monitor")) ---@diagnostic disable-line

    ---@diagnostic disable
    pModem = peripheral.find("modem")
    pEnergyDetectors = { peripheral.find("energyDetector") }
    ---@diagnostic enable

    if not pModem then error("No modem found") end

    pModem.open(RNET_CHANNEL)
end


local function main()
    local event, side, channel, replyChannel, message = os.pullEvent("modem_message")
    if event == "modem_message" then
        local net_packet = comms.net_packet()
        net_packet.receive(message)

        if net_packet.is_valid() then
            log.dmesg("modem_message(" .. channel .. "): " .. textutils.serialize(net_packet.data()))
        else
            log.dmesg("Ignored msg on " .. channel .. ": " .. textutils.serialize(message))
        end
    end
end

setup()
while true do
    local success, result = pcall(main)
    if not success then
        log.dmesg("Error: " .. result)
        print("\nError: " .. result)
        print("Press Strg+T to terminate autostart...")
        os.sleep(3)
    
    elseif result=="reload" then    -- ToDo: Status flag and actual reload functionality
        print("Reloading Supervisor...")
        setup()
    end
end