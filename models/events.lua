--[[
  models/events.lua — Flat-file agenda events model
  Stores events in data/events.json as an array sorted by event_date.
  Each event: id, title, description (markdown), event_date, created_at, author.
--]]

local DATA_FILE = "data/events.json"

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

local function read_events()
  local file = io.open(DATA_FILE, "r")
  if not file then return {} end
  local content = file:read("*a")
  file:close()
  if not content or content == "" then return {} end
  return require("lapis.util").from_json(content) or {}
end

local function write_events(events)
  local file = io.open(DATA_FILE, "w")
  if not file then return false, "Cannot open events data file" end

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
        local keys = {}
        for k in pairs(v) do table.insert(keys, k) end
        table.sort(keys)
        if #keys == 0 then return "{}" end
        local parts = {}
        for _, k in ipairs(keys) do
          table.insert(parts, pi .. '"' .. tostring(k) .. '": ' .. pp(v[k], i + 1))
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. p .. "}"
      end
    elseif type(v) == "string" then
      return '"' .. v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t') .. '"'
    elseif type(v) == "boolean" then return v and "true" or "false"
    elseif type(v) == "number" then return tostring(v)
    else return "null" end
  end

  file:write(pp(events))
  file:close()
  return true
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--[[
  Creates a new agenda event.

  Args:
    title        — string, event title
    description  — string, markdown description
    event_date   — string, ISO date/time of the event
    author       — string, username of creator
    location     — string or nil, event location
    rsvp_enabled — boolean, whether RSVP is enabled

  Returns:
    true, event_table on success
    false, error_message on failure
--]]
local function create(title, description, event_date, author, location, rsvp_enabled)
  if not title or #title < 1 then
    return false, "Title is required"
  end
  if not event_date or #event_date < 1 then
    return false, "Event date is required"
  end

  local events = read_events()

  local max_id = 0
  for _, e in ipairs(events) do
    if e.id and e.id > max_id then max_id = e.id end
  end

  local event = {
    id = max_id + 1,
    title = title,
    description = description or "",
    event_date = event_date,
    location = location or "",
    rsvp_enabled = rsvp_enabled or false,
    rsvps = {},
    author = author or "unknown",
    created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }

  table.insert(events, event)

  local ok, err = write_events(events)
  if not ok then return false, err end

  return true, event
end

--[[
  Updates an existing event by id.

  Args:
    id      — number, event id
    updates — table, fields: title, description, event_date, location, rsvp_enabled

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function update(id, updates)
  local events = read_events()
  for i, e in ipairs(events) do
    if e.id == id then
      if updates.title then e.title = updates.title end
      if updates.description then e.description = updates.description end
      if updates.event_date then e.event_date = updates.event_date end
      if updates.location then e.location = updates.location end
      if updates.rsvp_enabled ~= nil then
        if updates.rsvp_enabled == true or updates.rsvp_enabled == "true" then
          e.rsvp_enabled = true
        else
          e.rsvp_enabled = false
        end
      end
      events[i] = e
      local ok, err = write_events(events)
      if not ok then return false, err end
      return true, "Event updated"
    end
  end
  return false, "Event not found"
end

--[[
  Deletes an event by id.

  Args:
    id — number, event id

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function delete(id)
  local events = read_events()
  for i, e in ipairs(events) do
    if e.id == id then
      table.remove(events, i)
      local ok, err = write_events(events)
      if not ok then return false, err end
      return true, "Event deleted"
    end
  end
  return false, "Event not found"
end

--[[
  Finds an event by id.

  Args:
    id — number

  Returns:
    event_table or nil
--]]
local function find_by_id(id)
  for _, e in ipairs(read_events()) do
    if e.id == id then return e end
  end
  return nil
end

--[[
  Lists all events sorted by event_date ascending (upcoming first).

  Returns:
    array of event tables
--]]
local function list_all()
  local events = read_events()
  table.sort(events, function(a, b) return a.event_date < b.event_date end)
  return events
end

--[[
  Toggles a user's RSVP for an event. If the user has already RSVP'd they are
  removed; otherwise they are added.

  Args:
    event_id — number, the event id
    username — string, the username to toggle

  Returns:
    true, "rsvp" if added
    true, "unrsvp" if removed
    false, error_message on failure
--]]
local function toggle_rsvp(event_id, username)
  local events = read_events()
  for i, e in ipairs(events) do
    if e.id == event_id then
      if not e.rsvp_enabled then
        return false, "RSVP is not enabled for this event"
      end
      e.rsvps = e.rsvps or {}
      -- Check if user already RSVP'd
      for j, u in ipairs(e.rsvps) do
        if u == username then
          table.remove(e.rsvps, j)
          write_events(events)
          return true, "unrsvp"
        end
      end
      -- Add RSVP
      table.insert(e.rsvps, username)
      write_events(events)
      return true, "rsvp"
    end
  end
  return false, "Event not found"
end

--[[
  Lists upcoming events (event_date >= today) sorted ascending.

  Returns:
    array of event tables
--]]
local function list_upcoming()
  local today = os.date("!%Y-%m-%d")
  local result = {}
  for _, e in ipairs(read_events()) do
    if e.event_date >= today then
      table.insert(result, e)
    end
  end
  table.sort(result, function(a, b) return a.event_date < b.event_date end)
  return result
end

return {
  create = create,
  update = update,
  delete = delete,
  find_by_id = find_by_id,
  list_all = list_all,
  list_upcoming = list_upcoming,
  toggle_rsvp = toggle_rsvp,
}
