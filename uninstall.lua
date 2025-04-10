local filelist = {
  "/common/comms.lua",
  "/common/log.lua",
  "/common/util.lua",
  "/common",
  "/plc.lua",
  "/supervisor.lua",
  "/startup.lua",
  "/uninstall.lua"
}

print("Uninstalling RNet...")
for _, file in ipairs(filelist) do
  if fs.exists(file) then
    print("Removing " .. file .. "...")
    fs.delete(file)
  end
end