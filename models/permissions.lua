--[[
  models/permissions.lua — Central role & permission registry
  =============================================================
  This is the SINGLE source of truth for all roles, permission keys,
  defaults, and sidebar navigation links. Adding a new role or page
  only requires changes to the config tables below.
]]

local DATA_FILE = "data/permissions.json"

-- =========================================================================
-- CONFIG — edit these tables to add or change roles / permissions / nav
-- =========================================================================

-- All roles in the system, ordered highest privilege first
local ROLES = { "admin", "editor", "subscriber", "reader" }

-- Default role assigned to newly registered users
local DEFAULT_ROLE = "reader"

-- All permission keys and their human-readable labels.
-- Each key maps to a feature/page that can be allowed per role.
local PERMISSION_KEYS = {
  dashboard = "Dashboard",
  users     = "User Management",
  articles  = "Articles Editor",
  events    = "Events Editor",
  media     = "Media Library",
  agenda    = "Public Agenda",
  profile   = "Profile",
}

-- Default permissions assigned to each role (arrays of permission-key strings).
-- Roles not listed here get an empty set.
local DEFAULTS = {
  admin      = { "dashboard", "users", "articles", "events", "media", "agenda", "profile" },
  editor     = { "articles", "events", "media", "agenda", "profile" },
  subscriber = { "agenda", "profile" },
  reader     = { "agenda", "profile" },
}

-- Sidebar navigation links.
-- Each entry: { perm = "key", href = "/path", icon = "feather-name", label = "Text" }
-- Set perm = nil for links that appear for everyone (no permission check).
-- Set admin_only = true to restrict to admins regardless of permissions.
local SIDEBAR_LINKS = {
  { perm = "profile",   href = "/profile",        icon = "user",     label = "Profile" },
  { perm = "dashboard", href = "/admin",           icon = "home",     label = "Dashboard" },
  { perm = "users",     href = "/admin/users",     icon = "users",    label = "Users" },
  { perm = "articles",  href = "/admin/articles",  icon = "edit",     label = "Articles" },
  { perm = "events",    href = "/admin/events",    icon = "calendar", label = "Events" },
  { perm = "media",     href = "/admin/media",     icon = "image",    label = "Media" },
  { perm = nil,         href = "/admin/roles",     icon = "shield",   label = "Roles",    admin_only = true },
}

-- =========================================================================
-- Internal helpers
-- =========================================================================

local function read_file()
  local file = io.open(DATA_FILE, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  if not content or content == "" then return nil end
  return require("lapis.util").from_json(content)
end

local function write_file(data)
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

-- =========================================================================
-- Public API
-- =========================================================================

-- Returns the permission list for a role (array of keys). Falls back to defaults.
local function get(role)
  local data = read_file()
  if data and data[role] then return data[role] end
  return DEFAULTS[role] or {}
end

-- Returns all role→permissions. Unset roles use defaults.
local function get_all()
  local data = read_file() or {}
  local result = {}
  for _, role in ipairs(ROLES) do
    result[role] = data[role] or DEFAULTS[role] or {}
  end
  return result
end

-- Saves permissions for one role.
local function set(role, perms)
  local data = read_file() or {}
  data[role] = perms
  return write_file(data)
end

-- Checks whether a role has a specific permission.
local function check(role, perm)
  if not role or not perm then return false end
  local perms = get(role)
  for _, p in ipairs(perms) do
    if p == perm then return true end
  end
  return false
end

-- Validates whether a string is a recognised role.
local function is_valid_role(role)
  for _, r in ipairs(ROLES) do
    if r == role then return true end
  end
  return false
end

-- =========================================================================
-- Exports
-- =========================================================================

return {
  -- Config (read-only, use these everywhere instead of duplicating)
  ROLES          = ROLES,
  DEFAULT_ROLE   = DEFAULT_ROLE,
  PERMISSION_KEYS = PERMISSION_KEYS,
  SIDEBAR_LINKS  = SIDEBAR_LINKS,

  -- Functions
  get            = get,
  get_all        = get_all,
  set            = set,
  check          = check,
  is_valid_role  = is_valid_role,
}
