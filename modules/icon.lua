--[[
  modules/icon.lua — Feather SVG icon helper
  Reads an SVG from static/fonts/feather/ and returns it as inline markup.
  Usage: icon("user") -> '<svg ...>...</svg>'
]]

local ICON_DIR = "static/fonts/feather/"

-- Cache loaded SVGs (persists across requests only with lua_code_cache on)
local cache = {}

--[[
  Returns the inline SVG markup for a Feather icon by name.

  Args:
    name — string, icon name without extension (e.g. "user", "settings")

  Returns:
    string, the raw SVG markup, or an empty string if not found
--]]
local function icon(name)
  if cache[name] then return cache[name] end

  local path = ICON_DIR .. name .. ".svg"
  local file = io.open(path, "r")
  if not file then return "" end

  local svg = file:read("*a")
  file:close()

  -- Feather SVGs use 24x24 with stroke="currentColor" — remove fixed
  -- width/height so they can be sized via CSS, and add inline-block class
  svg = svg:gsub('width="24"', 'width="1em"')
  svg = svg:gsub('height="24"', 'height="1em"')

  cache[name] = svg
  return svg
end

return { icon = icon }
