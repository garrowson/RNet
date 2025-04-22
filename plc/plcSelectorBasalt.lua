local basalt = require("basalt")

-- Settings
local input = "chestIn"
local outOn = "left"
local outOff= "right"


-- Get the main frame (your window)
local main = basalt.getMainFrame()
main.term = peripheral.wrap("mon")

-- Add a close button
main:addButton()
    :setText("X")
    :setPosition(table.pack(main.term.getSize())[1] , 1)
    :setWidth(1)
    :setHeight(1)
    :setBackground(colors.red)
    :onClick(basalt.stop)

local flexbox = main:addFlexbox()
    :setSize("{parent.width}", "{parent.height-1}")
    :setPosition(1 , 2)
    :setFlexWrap(true)
    :setBackground(colors.gray)

function Switches(parent)
    self = {
        parent = parent,
        list = {}
    }

    public = {}

    function public.add(name)
        if self.list[name] then
            return false
        end

        local sw = {}
        sw.state = false
        sw.btn = self.parent:addButton():setText(name)

        function sw.On()
            sw.state = true
            sw.btn:setBackground(colors.green)
        end

        function sw.Off()
            sw.state = false
            sw.btn:setBackground(colors.red)
        end

        sw.btn:onClick(function()
            if sw.state then sw.Off() else sw.On() end
        end)

        self.list[name] = sw
        
        return true
    end
    
    function public.toggleSwitch(name)
        local sw = self.list[name]
        if sw then
            if sw.state then sw.Off() else sw.On() end
        end
    end
    
    function public.updateRender()
        os.queueEvent("")   -- queue empty event to force render
    end

    return public
end

switches = Switches(flexbox)
switches.add("Redstone")
switches.add("Iron Comb")
switches.add("Gold Comb")
switches.add("Draconic Comb")
switches.add("Spatial Comb")
switches.add("Experience Comb")


function main()
    local timer = os.startTimer(5)
    while true do
        local event = {os.pullEvent()}
        if event[1] == "timer" and timer==event[2] then
            switches.toggleSwitch("Redstone")
            switches.toggleSwitch("Experience Comb")
            switches.updateRender()
        end
    end
end


parallel.waitForAny(basalt.run, main)
peripheral.call("mon", "clear")
