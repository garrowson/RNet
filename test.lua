

local comms = require("common/comms")

local pModem ---@type Modem
pModem = peripheral.find("modem") ---@diagnostic disable-line

local RNET_CHANNEL = settings.get("rnet.channel")


local net_pkt = comms.net_packet()
local req_pkt = comms.req_transferrate_packet()

req_pkt.make({}, {1})
net_pkt.make(comms.BROADCAST, comms.PROTOCOL.REQUEST_TRANSFERRATE, req_pkt.raw_sendable())

print(textutils.serialize(net_pkt.raw_sendable()))
pModem.transmit(RNET_CHANNEL, RNET_CHANNEL, net_pkt.raw_sendable())