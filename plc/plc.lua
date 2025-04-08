-- 
--  PLC - Programmable Logic Controller, acts as sensor and actuator
--
local comms = require("comms")


local DEBUG = false
local version = "0.1"

local PROTOCOL = comms.PROTOCOL


-- For now, keep it simple
local pModem = peripheral.find("modem")
if not pModem then
    error("No modem found")
end

while true do
    local event, side, channel, replyChannel, message = os.pullEvent("modem_message")
    if event == "modem_message" then
        local net_packet = comms.net_packet()
        net_packet.tryParsePacket(message)

        if net_packet.is_valid() then
            if net_packet.protocol() == PROTOCOL.UNSECRAW then
                local rawdata = net_packet.rawdata()

                if DEBUG then print("Dbg: modem_message(UNSECRAW): " .. textutils.serialize(rawdata)) end
            end


        elseif DEBUG then
            print("Dbg: Ignored msg on " .. channel .. ": " .. textutils.serialize(message))
        end
    end
end
