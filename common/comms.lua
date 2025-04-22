--
-- Communications
--

local log = require("common/log")

local comms = {}

comms.VERSION = "0.1.0"

---@enum PROTOCOL
local PROTOCOL = {
    UNSECRAW = 0,
    ADVERTISE = 1,
    REQUEST_TRANSFERRATE = 2,
    REQUEST_TRANSFERRATE_REPLY = 3,
    PERIPHERALDATA = 4,
}

---@enum PERIPHERALDATATYPE
local PERIPHERALDATATYPE = {
    UNKNOWN = 0,
    TRANSFERRATE = 1,
}

comms.PROTOCOL = PROTOCOL
comms.PERIPHERALDATATYPE = PERIPHERALDATATYPE

comms.BROADCAST = -1

-- peripheral data packet
function comms.peripheraldata_packet()
    local self = {
        frame = {},
        peripheralName = "NaN", ---@type string
        peripheralDataType = PERIPHERALDATATYPE.UNKNOWN, ---@type PERIPHERALDATATYPE
        data = {}, ---@type table
    }

    ---@class peripheraldata_packet
    local public = {}

    -- make an peripheraldata packet
    ---@param peripheralDataType PERIPHERALDATATYPE
    function public.make(peripheralName, peripheralDataType)
        self.peripheralName = peripheralName
        self.peripheralDataType = peripheralDataType
        self.raw = { self.peripheralName, self.peripheralDataType, self.data }
    end

    -- decode an peripheraldata packet
    ---@param frame net_packet
    ---@return boolean valid
    function public.decode(frame)
        if frame then
            self.frame = frame
            if frame.protocol() == PROTOCOL.PERIPHERALDATA then
                if type(frame.data()) == "table" and #frame.data() == 3 then
                    local data = frame.data()
                    self.data = data[3]
                    public.make(data[1], data[2])

                else
                    log.debug("attempted PERIPHERALDATA parse of incorrect data type " .. type(frame.data()), true)
                    return false
                end
            else
                log.debug("attempted UNSECRAW parse of incorrect protocol " .. frame.protocol(), true)
                return false
            end

            local valid = type(self.peripheralName) == "string" and
                        type(self.peripheralDataType) == "number" and
                        type(self.data) == "table"
            return valid
        end
        return false
    end

    function public.raw_sendable() return self.raw end
    function public.get_peripheralName() return self.peripheralName end
    function public.get_peripheralDataType() return self.peripheralDataType end
    function public.get_data() return self.data end
    function public.set_data(data)
        if type(data) == "table" then
            self.data = data
            self.raw = { self.peripheralDataType, self.data }
            return true
        else
            log.debug("attempted to set data to non-table type " .. type(data), true)
            return false
        end
    end

    return public
end

-- reqest_transferrate packet
---@deprecated
function comms.req_transferrate_packet()
    local self = {
        frame = {},
        peripheralNames = {},
        peripheralIds = {},
        raw = {}
    }

    ---@class reqest_transferrate
    local public = {}

    -- make an reqest_transferrate packet
    ---@param peripheralNames table
    ---@param peripheralIds table
    function public.make(peripheralNames, peripheralIds)
        self.peripheralNames = peripheralNames
        self.peripheralIds = peripheralIds
        self.raw = { self.peripheralNames, self.peripheralIds }
    end

    -- decode an requesting_transferrate packet
    ---@param frame net_packet
    ---@return boolean valid
    function public.decode(frame)
        if frame then
            self.frame = frame
            if frame.protocol() == PROTOCOL.REQUEST_TRANSFERRATE then
                local data = frame.data()
                public.make(data[1], data[2])

                local valid = type(self.peripheralNames) == "table" and
                    type(self.peripheralIds) == "table"

                return valid
            else
                log.debug("attempted REQUEST_TRANSFERRATE parse of incorrect protocol " .. frame.protocol(), true)
                return false
            end
        end
        return false
    end

    function public.raw_sendable() return self.raw end
    function public.get_peripheralNames() return self.peripheralNames end
    function public.get_peripheralIds() return self.peripheralIds end

    return public
end

-- reqest_transferrate_reply packet
---@deprecated
function comms.req_transferrate_reply_packet()
    local self = {
        frame = {},
        dataForNamed = {},
        dataForIds = {},
        raw = {}
    }

    ---@class reqest_transferrate_reply
    local public = {}

    -- make an reqest_transferrate_reply packet
    ---@param dataForNamed table
    ---@param dataForIds table
    function public.make(dataForNamed, dataForIds)
        self.dataForNamed = dataForNamed
        self.dataForIds = dataForIds
        self.raw = { self.dataForNamed, self.dataForIds }
    end

    -- decode an reqest_transferrate_reply packet
    ---@param frame net_packet
    function public.decode(frame)
        if frame then
            self.frame = frame
            if frame.protocol() == PROTOCOL.REQUEST_TRANSFERRATE_REPLY then
                local data = frame.data()
                public.make(data[1], data[2])

                local valid = type(self.dataForNamed) == "table" and
                    type(self.dataForIds) == "table"

                return valid
            else
                log.debug("attempted REQUEST_TRANSFERRATE_REPLY parse of incorrect protocol " .. frame.protocol(), true)
                return false
            end
            
        end
    end

    function public.raw_sendable() return self.raw end
    function public.get_dataForNamed() return self.dataForNamed end
    function public.get_dataForIds() return self.dataForIds end

    return public
end

-- advertising packet
function comms.advertise_packet()
    local self = {
        frame = {},
        peripheralType = "NaN",
        peripheralNames = {},
        peripheralIds = {},
        peripheralCount = 0,
        raw = {}
    }

    ---@class advertise_packet
    local public = {}

    -- make an advertising packet
    ---@param peripheralType string
    ---@param peripheralNames table
    ---@param peripheralIds table
    ---@param peripheralCount number
    function public.make(peripheralType, peripheralNames, peripheralIds, peripheralCount)
        self.peripheralType = peripheralType
        self.peripheralNames = peripheralNames
        self.peripheralIds = peripheralIds
        self.peripheralCount = peripheralCount
        self.raw = { self.peripheralType, self.peripheralNames, self.peripheralIds, self.peripheralCount }
    end

    -- decode an advertising packet
    ---@param frame net_packet
    function public.decode(frame)
        if frame then
            self.frame = frame
            if frame.protocol() == PROTOCOL.ADVERTISE then
                local data = frame.data()
                public.make(data[1], data[2], data[3], data[4])

                local valid = type(self.peripheralType) == "string" and
                    type(self.peripheralNames) == "table" and
                    type(self.peripheralIds) == "table" and
                    type(self.peripheralCount) == "number"

                return valid
            else
                log.debug("attempted ADVERTISE parse of incorrect protocol " .. frame.protocol(), true)
                return false
            end
            
        end
    end

    function public.raw_sendable() return self.raw end

    return public
end

-- generic net_packet
function comms.net_packet()
    local self = {
        src_adr = comms.BROADCAST,
        dst_adr = comms.BROADCAST,
        protocol = nil, ---@type PROTOCOL
        payload = nil, ---@type table
        is_valid = true,
        raw = {}
    }

    ---@class net_packet
    local public = {}
    
    function public.make(dest_addr, protocol, payload)
        self.is_valid = true
        self.src_adr = os.computerID()
        self.dst_adr = dest_addr
        self.protocol = protocol
        self.payload = payload
        self.raw = { self.src_adr, self.dst_adr, self.protocol, self.payload }
    end

    -- parse in a modem message as net_packet
    ---@param message any message body
    function public.receive(message)
        self.raw = message
        self.is_valid = false

        if type(self.raw) == "table" then
            if #self.raw == 4 then
                self.src_adr = self.raw[1]
                self.dst_adr = self.raw[2]
                self.protocol = self.raw[3]

                if type(self.raw[4]) == "table" then
                    self.payload = self.raw[4]
                end
            else
                self.src_adr = nil
                self.dst_adr = nil
                self.protocol = nil
                self.payload = {}
            end

            local is_destination = (self.dst_adr == comms.BROADCAST or self.dst_adr == os.computerID())

            self.is_valid = is_destination and 
                type(self.src_adr) == "number" and
                type(self.dst_adr) == "number" and
                type(self.protocol) == "number" and
                type(self.payload) == "table"
                
        end

        return self.is_valid
    end

    function public.is_valid() return self.is_valid end
    function public.protocol() return self.protocol end
    function public.raw_sendable() return self.raw end
    function public.src_adr() return self.src_adr end
    function public.dst_adr() return self.dst_adr end
    function public.data() return self.payload end


    return public
end

return comms