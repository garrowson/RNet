local log = require("common/log")
log.init("/dmesg.log", log.MODE.NEW, true, term.current()) ---@diagnostic disable-line


if not fs.exists("basalt.lua") then
    log.dmesg("Basalt not found, installing...")
    shell.run("wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -r")
end
local basalt = require("basalt")

-- Settings
local SETTINGPREFIX = "plcselect."
local input = settings.get(SETTINGPREFIX .. "input", nil)
local outOn = settings.get(SETTINGPREFIX .. "outOn", nil)
local outOff= settings.get(SETTINGPREFIX .. "outOff", nil)
local cycletime = settings.get(SETTINGPREFIX .. "cycle", 10)
local roundRobin = settings.get(SETTINGPREFIX .. "roundRobin", false)
local blockingMode = settings.get(SETTINGPREFIX .. "blockingMode", false)
local storedStates = settings.get(SETTINGPREFIX .. "storedStates", 0)
local bundledSide = settings.get(SETTINGPREFIX .. "bundledSide", nil)

-- Global variables
---@diagnostic disable-next-line: missing-fields
local switches = { }    ---@type Switches
local lastRoundRobinIndex = 0

local pInput = peripheral.wrap(input) ---@diagnostic disable need-check-nil
if not pInput and input ~= nil then
    log.dmesg("Input inventory not found", "ERROR", colors.red)
    print() -- next line
    return
end

---Provides a simple interface to add switches to a frame
---@param parent any The parent frame to add the switches to
---@return Switches
function Switches(parent)
    local self = {
        parent = parent,
        list = {},
        count = 0
    }

    ---@class Switches
    local public = {}

    ---Adds a switch to the frame
    ---@param name string Text and identifier of the switch
    ---@return boolean success
    function public.add(name)
        if self.list[name] or self.count >= 16 then
            return false
        end

        local sw = {}
        sw.state = false
        sw.name = name
        sw.btn = self.parent:addButton():setText(sw.name)
        sw.color = 2^self.count
        self.count = self.count + 1

        ---Sets the state of the switch. Will queue an event "switch" with the name and state of the switch
        ---@param state boolean
        function sw.setState(state)
            sw.state = state
            sw.btn:setBackground(state and colors.green or colors.red)
            os.queueEvent("switch", sw.name, sw.state, sw.color)
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

    ---Returns a table with the states of all switches
    ---@return table states[name] boolean
    function public.getAllSwitchStates()
        local states = {}
        for name, sw in pairs(self.list) do
            states[name] = sw.state
        end
        return states
    end

    ---Returns the bundled representation of the switches
    ---@return colorSet bundledState The bundled representation of activated siches
    function public.getAllSwitchBundled()
        local bundledState = 0
        for _, sw in pairs(self.list) do
            if sw.state then
                bundledState = bundledState + sw.color
            end
        end
        return bundledState
    end

    ---Toggles or sets the state of the switch
    ---@param name string Name of the switch
    ---@param state boolean State the switch should be set to
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

    ---Returns the asociated color of the switch
    ---@param name string Name of the switch
    ---@return color Returns associated color of the switch
    function public.getSwitchColor(name)
        local sw = self.list[name]
        if sw then
            return sw.color
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

---Loads buttons from file and returns the loaded list
---@return table table list of known items
local function loadButtonsFromFile()
    local knownItems = {}

    local file = fs.open("knownItems.txt", "r")
    if file then
        local line = file.readLine()

        for i=0, 15 do
            if not line then break end
            local index = line:find("|")
            local name = line:sub(1, index-1)
            local desc = line:sub(index+1)

            knownItems[name] = desc

            switches.add(desc)
            switches.toggleSwitch(desc, colors.test(storedStates, 2^i))

            line = file.readLine()
        end
        file.close()
    end

    return knownItems
end

---Moves items from input to output1 or output2 depending on the state of the coresponding switche
---@param roundRobin boolean Should items be moved in round robin mode?
local function moveItems(roundRobin)
    local selectedItem = ""
    if roundRobin then
      -- determine the next round robin item
        local states = switches.getAllSwitchStates()
        local statesOn = {}
        for descName, state in pairs(states) do
            if state then
                table.insert(statesOn, descName)
            end
        end

        if #statesOn > 0 then
            lastRoundRobinIndex = lastRoundRobinIndex +1
            if lastRoundRobinIndex > #statesOn then
                lastRoundRobinIndex = 1
            end
            selectedItem = statesOn[lastRoundRobinIndex]
        end
        log.debug("RoundRobin mode list: " .. textutils.serialise(statesOn, { compact = true }))
        log.debug("Selected index: " .. lastRoundRobinIndex .. " - " .. selectedItem)
    end

    -- loop input for items
    for i = 1, pInput.size() do
        local item = pInput.getItemDetail(i)
        if item then
            if Lookupdict[item.name] then
                local descName = Lookupdict[item.name]
                if selectedItem ~= "" then
                  if selectedItem==descName then
                    local count = pInput.pushItems(outOn, i)
                    if count==0 then
                      if blockingMode then
                        log.debug("Moved 0 items while in forced round robin mode - retrying next round")
                        lastRoundRobinIndex = lastRoundRobinIndex -1
                      else
                        log.debug("Moved 0 items while in round robin mode - skipping")
                      end
                    end
                  end
                else
                    local state = switches.getSwitchState(descName)
                    if state~=nil then
                        if state then
                            pInput.pushItems(outOn, i)
                        else
                            if outOff then
                                pInput.pushItems(outOff, i)
                            end
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
        local rawevent = {os.pullEvent()}
        local event = table.remove(rawevent, 1)
        if event == "timer" and timer==rawevent[1] then
            timer = os.startTimer(cycletime)
            
            if pInput then moveItems(roundRobin) end

        elseif event == "switch" then
            local name, state, color = table.unpack(rawevent)

            settings.set(SETTINGPREFIX .. "storedStates", switches.getAllSwitchBundled())
            settings.save()

            log.debug(textutils.serialize(event, { compact = true }))
        end

        if bundledSide then
            redstone.setBundledOutput(bundledSide, switches.getAllSwitchBundled())
        end
    end
end

-- ----------------------------------------
-- START
-- ----------------------------------------
local frame = setupBasalt()
switches = Switches(frame)
Lookupdict = loadButtonsFromFile()

parallel.waitForAny(basalt.run, maineventloop)

-- cleanup
if bundledSide then
    redstone.setBundledOutput(bundledSide, 0)
end