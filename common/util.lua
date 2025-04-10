--
-- Utility Functions
--


---@class util
local util = {}

-- get a value as a string
---@nodiscard
---@param val any
---@return string
function util.strval(val)
  local t = type(val)
  -- this depends on Lua short-circuiting the or check for metatables (note: metatables won't have metatables)
  if (t == "table" and (getmetatable(val) == nil or getmetatable(val).__tostring == nil)) or t == "function" then
      return "[" .. tostring(val) .. "]"
  else
      return tostring(val)
  end
end

-- concatenation with built-in to string
---@nodiscard
---@vararg any
---@return string
---@diagnostic disable-next-line: unused-vararg
function util.concat(...)
  local str = ""

  for _, v in ipairs(arg) do str = str .. util.strval(v) end

  return str
end

-- alias
util.c = util.concat

return util