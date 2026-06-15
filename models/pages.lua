--[[ models/pages.lua — custom pages (About, Contact, etc.) ]]
local DB = "data/pages.json"
local J = require("modules.json_util")

local function create(title, slug, content, content_type, location)
  local all = J.read(DB)
  local max_id = 0
  for _, p in ipairs(all) do if p.id and p.id > max_id then max_id = p.id end end
  local page = {
    id = max_id + 1,
    title = title,
    slug = slug or title:lower():gsub("[^a-z0-9%-]", "-"):gsub("%-+", "-"),
    content = content or "",
    content_type = content_type or "html",
    location = location or "nav",
    created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  table.insert(all, page)
  return J.write(DB, all), page
end

local function update(id, updates)
  local all = J.read(DB)
  for i, p in ipairs(all) do
    if p.id == id then
      if updates.title    then p.title    = updates.title end
      if updates.slug     then p.slug     = updates.slug end
      if updates.content      then p.content      = updates.content end
      if updates.content_type then p.content_type = updates.content_type end
      if updates.location     then p.location     = updates.location end
      p.updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
      all[i] = p
      return J.write(DB, all), "Page updated"
    end
  end
  return false, "Page not found"
end

local function delete(id)
  local all = J.read(DB)
  for i, p in ipairs(all) do
    if p.id == id then table.remove(all, i) return J.write(DB, all), "Page deleted" end
  end
  return false, "Page not found"
end

local function find_by_slug(slug)
  for _, p in ipairs(J.read(DB)) do
    if p.slug == slug then return p end
  end
end

local function find_by_id(id)
  for _, p in ipairs(J.read(DB)) do
    if p.id == id then return p end
  end
end

local function list_by_location(loc)
  local result = {}
  for _, p in ipairs(J.read(DB)) do
    if p.location == loc then table.insert(result, p) end
  end
  return result
end

local function list_all()
  return J.read(DB)
end

return { create=create, update=update, delete=delete, find_by_slug=find_by_slug, find_by_id=find_by_id, list_by_location=list_by_location, list_all=list_all }
