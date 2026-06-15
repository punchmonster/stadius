--[[ models/campaigns.lua — campaigns with progress tracking ]]
local DB = "data/campaigns.json"
local J = require("modules.json_util")

local function create(title, description, goal_type, goal_target, goal_current)
  local all = J.read(DB)
  local max_id = 0
  for _, c in ipairs(all) do if c.id and c.id > max_id then max_id = c.id end end
  local c = {
    id = max_id + 1,
    title = title, description = description or "",
    goal_type = goal_type or "percent",
    goal_target = tonumber(goal_target) or 100,
    goal_current = tonumber(goal_current) or 0,
    header_image = nil,
    created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  table.insert(all, c)
  return J.write(DB, all), c
end

local function update(id, updates)
  local all = J.read(DB)
  for i, c in ipairs(all) do
    if c.id == id then
      if updates.title          then c.title          = updates.title end
      if updates.description    then c.description    = updates.description end
      if updates.goal_type      then c.goal_type      = updates.goal_type end
      if updates.goal_target    then c.goal_target    = tonumber(updates.goal_target) or c.goal_target end
      if updates.goal_current   then c.goal_current   = tonumber(updates.goal_current) or c.goal_current end
      if updates.header_image   then c.header_image   = updates.header_image end
      all[i] = c
      return J.write(DB, all), "Campaign updated"
    end
  end
  return false, "Campaign not found"
end

local function delete(id)
  local all = J.read(DB)
  for i, c in ipairs(all) do
    if c.id == id then table.remove(all, i) return J.write(DB, all), "Campaign deleted" end
  end
  return false, "Campaign not found"
end

local function find_by_id(id)
  for _, c in ipairs(J.read(DB)) do if c.id == id then return c end end
end

local function list_all()
  return J.read(DB)
end

local function progress_pct(c)
  local target = tonumber(c.goal_target) or 0
  local current = tonumber(c.goal_current) or 0
  if target == 0 then return 0 end
  return math.min(100, math.floor((current / target) * 100))
end

return { create=create, update=update, delete=delete, find_by_id=find_by_id, list_all=list_all, progress_pct=progress_pct }
