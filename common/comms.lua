--
-- Communications
--

local comms = {}

comms.version = "0.1"

---@enum PROTOCOL
local PROTOCOL = {
    UNSECRAW = 0,
}

-- generic net_packet
function comms.net_packet()
    local self = {
        is_valid = true,
        protocol = nil,
        rawdata = nil,

    }

    ---@class net_packet
    local public = {}
    
    ---@param packet net_packet a generic network packet
    function public.tryParsePacket(packet)
        if packet.protocol==nil or packet.data==nil then self.is_valid = false end
    end

    function public.is_valid() return self.is_valid end
    function public.protocol() return self.protocol end
    function public.rawdata() return self.rawdata end


    return public
end


function comms.example_packet()
    local self = {
        ex1 = 0,
        ex2 = 0
    }

    ---@class example_packet
    local public = {}

    -- make an example packet
    ---@param example1 number
    ---@param example2 number
    function public.make(example1, example2)
        self.ex1 = example1
        self.ex2 = example2
    end

    -- decode an example packet
    ---@param frame net_packet
    function public.decode(frame)
        if frame then
            self.frame = frame
        end
    end


end

comms.PROTOCOL = PROTOCOL

return comms