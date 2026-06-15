--[[ modules/json_util.lua — shared JSON read/write with pretty printing ]]
local util = require("lapis.util")

-- Pretty-print a Lua value as JSON with 2-space indent.
local function pp(v, i)
  i = i or 0
  local p = string.rep("  ", i)
  local pi = string.rep("  ", i + 1)
  if type(v) == "table" then
    local is_array, mk = true, 0
    for k in pairs(v) do
      if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then is_array = false break end
      if k > mk then mk = k end
    end
    if is_array and mk > 0 then
      local parts = {}
      for idx = 1, mk do table.insert(parts, pi .. pp(v[idx], i + 1)) end
      return "[\n" .. table.concat(parts, ",\n") .. "\n" .. p .. "]"
    else
      local ks = {}
      for k in pairs(v) do table.insert(ks, k) end
      table.sort(ks)
      if #ks == 0 then return "{}" end
      local parts = {}
      for _, k in ipairs(ks) do
        table.insert(parts, pi .. '"' .. tostring(k) .. '": ' .. pp(v[k], i + 1))
      end
      return "{\n" .. table.concat(parts, ",\n") .. "\n" .. p .. "}"
    end
  elseif type(v) == "string" then
    return '"' .. v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\r','\\r'):gsub('\n','\\n') .. '"'
  elseif type(v) == "boolean" then return v and "true" or "false"
  elseif type(v) == "number" then return tostring(v)
  else return "null" end
end

-- Read JSON file, return empty table on failure.
local function read_json(path)
  local file = io.open(path, "r")
  if not file then return {} end
  local content = file:read("*a")
  file:close()
  if not content or content == "" then return {} end
  return util.from_json(content) or {}
end

-- Write table to JSON file with pretty printing.
local function write_json(path, data)
  local file = io.open(path, "w")
  if not file then return false end
  file:write(pp(data))
  file:close()
  return true
end

return { read = read_json, write = write_json }
