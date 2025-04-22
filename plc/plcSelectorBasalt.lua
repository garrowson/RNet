local basalt = require("basalt")

-- Settings
local input = "chestIn"
local outOn = "left"
local outOff= "right"


-- Get the main frame (your window)
local main = basalt.getMainFrame()
main.term = peripheral.wrap("monitor_0")

-- Add a close button
main:addButton()
    :setText("X")
    :setPosition(table.pack(main.term.getSize())[1] , 1)
    :setWidth(1)
    :setHeight(1)
    :setBackground(colors.red)
    :onClick(basalt.stop)

local cont = main:addContainer()
    :setSize("{parent.width}", "{parent.height-1}")
    :setPosition(1, 2)

local flexbox = cont:addFlexbox()
    :setSize("{parent.width-8}", "{parent.height-2}")
    :setPosition(5, 2)
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
        sw.name = name
        sw.btn = self.parent:addButton():setText(sw.name)

        function sw.setState(state)
            sw.state = state
            sw.btn:setBackground(state and colors.green or colors.red)
            os.queueEvent("switch", sw.name, sw.state)
        end

        sw.btn:onClick(function() sw.setState(not sw.state) end)

        self.list[name] = sw
        
        return true
    end

    function public.toggleSwitch(name, state)
        local sw = self.list[name]
        if sw then
            if state==nil then
                sw.setState(not sw.state)
            else 
                sw.setState(state)
            end
        end
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
for i=1,16 do
    switches.add("Test " .. i)
end


function main()
    local timer = os.startTimer(5)
    while true do
        local event = {os.pullEvent()}
        if event[1] == "timer" and timer==event[2] then
            switches.toggleSwitch("Redstone")
            switches.toggleSwitch("Iron Comb")

            switches.toggleSwitch("Gold Comb", true)
            switches.toggleSwitch("Draconic Comb", false)


        elseif event[1] == "switch" then
            print(textutils.serialize(event, { compact = true }))
        end
    end
end


parallel.waitForAny(basalt.run, main)
peripheral.call("monitor_0", "clear")
