
local VERSION = "0.1.0"

local log = require("common/log")
log.init("/dmesg.log", log.MODE.NEW, true, term.current()) ---@diagnostic disable-line

term.clear()
term.setCursorPos(1, 1)

if shell.getRunningProgram() ~= "startup.lua" then
  log.dmesg("RNet - Starting up from disk...", "Disk")
  os.sleep(2)
  if fs.exists("/startup.lua") then
    log.dmesg("Local startup file exists!", "Disk")
    log.dmesg("Terminating and starting up from local instead...", "Disk")
    os.sleep(2)
    shell.run("/startup.lua")
    return
  end

  log.dmesg("Installing RNet...", "Disk")

  local diskPath = shell.getRunningProgram()
  diskPath = diskPath:sub(1, #diskPath - 12) -- remove startup.lua

  if fs.exists("/uninstall.lua") then shell.run("/uninstall.lua") end -- remove old installation if exists

  local filelist = {
    "/common",
    "/plc.lua",
    "/supervisor.lua",
    "/startup.lua",
    "/uninstall.lua"
  }
  
  log.dmesg("Copying files from disk...", "Disk")
  for _, file in ipairs(filelist) do
    log.dmesg("Copying " .. file .. "...", "Disk")
    fs.copy(diskPath .. file, file)
  end

  log.dmesg("RNet v" .. VERSION .. " installed!", "Disk")

else
  log.dmesg("RNet v" .. VERSION .. " - Starting up...")
end

log.dmesg("Loading settings")
os.sleep(0.1)

local settings_valid = true
if settings.get("rnet.channel") == nil then settings_valid = false end

if not settings_valid then
  log.dmesg("No environment settings found!")
  log.dmesg("Opening settings menu...")
  os.sleep(0.5)

  -- ToDo: Open settings menu
  error("Not yet implemented!")

end
log.dmesg("Settings loaded")

if settings.get("rnet.supervisor") then
  log.dmesg("Starting as PLC")
  log.close()
  os.sleep(1)
  shell.run("plc.lua")

else
  log.dmesg("Starting as Supervisor")
  log.close()
  os.sleep(1)
  shell.run("supervisor.lua")

end

