--[[
  models/media.lua — Image metadata store
  Stores metadata about uploaded images in data/media.json.
  Each record: id, filename, title, alt_text, credit, tags, uploaded_by,
  uploaded_at, file_size
--]]

local DATA_FILE = "data/media.json"

-- Internal ----------------------------------------------------------------
local function read_all()
  local file = io.open(DATA_FILE, "r")
  if not file then return {} end
  local content = file:read("*a")
  file:close()
  if not content or content == "" then return {} end
  return require("lapis.util").from_json(content) or {}
end

local function write_all(data)
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
        for k in pairs(v) do table.insert(ks, k) end table.sort(ks)
        if #ks == 0 then return "{}" end
        local parts = {}
        for _, k in ipairs(ks) do
          table.insert(parts, pi .. '"' .. tostring(k) .. '": ' .. pp(v[k], i + 1))
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. p .. "}"
      end
    elseif type(v) == "string" then
      return '"' .. v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n') .. '"'
    elseif type(v) == "boolean" then return v and "true" or "false"
    elseif type(v) == "number" then return tostring(v)
    else return "null" end
  end
  local file = io.open(DATA_FILE, "w")
  if not file then return false end
  file:write(pp(data))
  file:close()
  return true
end

-- Public ------------------------------------------------------------------
local function create(filename, title, alt_text, credit, tags, uploaded_by, file_size)
  local all = read_all()
  local max_id = 0
  for _, m in ipairs(all) do if m.id and m.id > max_id then max_id = m.id end end
  local record = {
    id = max_id + 1,
    filename = filename,
    title = title or "",
    alt_text = alt_text or "",
    credit = credit or "",
    tags = tags or {},
    uploaded_by = uploaded_by or "",
    uploaded_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    file_size = file_size or 0,
  }
  table.insert(all, record)
  return write_all(all), record
end

local function find_by_filename(filename)
  for _, m in ipairs(read_all()) do
    if m.filename == filename then return m end
  end
  return nil
end

local function find_by_id(id)
  for _, m in ipairs(read_all()) do
    if m.id == id then return m end
  end
  return nil
end

local function list_all()
  local all = read_all()
  table.sort(all, function(a, b) return a.uploaded_at > b.uploaded_at end)
  return all
end

local function delete(id)
  local all = read_all()
  for i, m in ipairs(all) do
    if m.id == id then table.remove(all, i) return write_all(all) end
  end
  return false
end

return { create = create, find_by_filename = find_by_filename, find_by_id = find_by_id, list_all = list_all, delete = delete }
