--[[
  models/media.lua — Image metadata store
  Stores metadata about uploaded images in data/media.json.
  Each record: id, filename, title, alt_text, credit, tags, uploaded_by,
  uploaded_at, file_size
--]]

local DB = "data/media.json"
local J = require("modules.json_util")
local read_all = function() return J.read(DB) end
local write_all = function(data) return J.write(DB, data) end

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
