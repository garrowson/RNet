local log = require("common/log")
log.init("/dmesg.log", log.MODE.NEW, true, term.current()) ---@diagnostic disable-line


if not fs.exists("basalt.lua") then
    log.dmesg("Basalt not found, installing...")
    shell.run("wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -r")
end
local basalt = require("basalt")

-- Settings
local input = peripheral.wrap("back")
local outOn = "bottom"
local outOff= nil
local cycletime = 10

-- Global variables
local switches = {}

if input == nil then log.dmesg("No input inventory found") return end

---Provides a simple interface to add switches to a frame
---@param parent any The parent frame to add the switches to
---@return Switches
function Switches(parent)
    local self = {
        parent = parent,
        list = {}
    }

    ---@class Switches
    local public = {}

    ---Adds a switch to the frame
    ---@param name string Text and identifier of the switch
    ---@return boolean success
    function public.add(name)
        if self.list[name] then
            return false
        end

        local sw = {}
        sw.state = false
        sw.name = name
        sw.btn = self.parent:addButton():setText(sw.name)

        ---Sets the state of the switch. Will queue an event "switch" with the name and state of the switch
        ---@param state boolean
        function sw.setState(state)
            sw.state = state
            sw.btn:setBackground(state and colors.green or colors.red)
            os.queueEvent("switch", sw.name, sw.state)
        end

        sw.btn:onClick(function() sw.setState(not sw.state) end)

        self.list[name] = sw
        
        return true
    end

    ---Returns the state of the switch or nil if the switch does not exist
    ---@param name string
    function public.getSwitchState(name)
        if self.list[name] then
            return self.list[name].state
        else
            return nil
        end
    end

    ---Toggles or sets the state of the switch
    ---@param name string
    ---@param state boolean
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

---Prepares the basalt UI
local function setupBasalt()
   -- Get the main frame (your window)
    local main = basalt.getMainFrame()

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

    return flexbox
end

---Shorten the descriptive name of the item by removing spaces and vocals if the name is longer than 10 characters
---@param name string
local function shortenDescriptiveName(name)
    if #name > 10 then
        name = name:gsub(" ", ""):gsub("[aeiou]", "")
        if #name > 10 then
            name = name:sub(1, 10)
        end
    end
    return name
end

---Reads previously learned items from file and searches through input container to learn possible new items
---@param container any
local function learnButtons(container)
    local knownItems = {}

    local file = fs.open("knownItems.txt", "r")
    if file then
        local line = file.readLine()
        while line do
            local index = line:find("|")
            local name = line:sub(1, index-1)
            local desc = line:sub(index+1)

            knownItems[name] = desc
            line = file.readLine()
        end
        file.close()
    end

    for i = 1, input.size() do
        local item = input.getItemDetail(i)
        if item then
            local name = item.name
            if not knownItems[name] then
                knownItems[name] = shortenDescriptiveName(item.displayName)
                local file = fs.open("knownItems.txt", "a")
                file.writeLine(name .. "|" .. knownItems[name])
                file.close()
            end
        end
    end

    switches = Switches(container)
    for name, descname in pairs(knownItems) do
        switches.add(descname)
        switches.toggleSwitch(descname, false)
    end

    return knownItems
end

---Moves items from input to output1 or output2 depending on the state of the coresponding switche
local function moveItems()
    for i = 1, input.size() do
        local item = input.getItemDetail(i)
        if item then
            if Lookupdict[item.name] then
                local descName = Lookupdict[item.name]
                local state = switches.getSwitchState(descName)
                if state~=nil then
                    if state then
                        input.pushItems(outOn, i)
                    else
                        if outOff then
                           input.pushItems(outOff, i)
                        end
                    end
                end
            end
        end
    end
end

---Main event loop
local function maineventloop()
    local timer = os.startTimer(cycletime)
    while true do
        local event = {os.pullEvent()}
        if event[1] == "timer" and timer==event[2] then
            timer = os.startTimer(cycletime)
            moveItems()

        elseif event[1] == "switch" then
            log.debug(textutils.serialize(event, { compact = true }))
        end
    end
end

-- ----------------------------------------
-- MAIN
-- ----------------------------------------
local frame = setupBasalt()
Lookupdict = learnButtons(frame)

parallel.waitForAny(basalt.run, maineventloop)

