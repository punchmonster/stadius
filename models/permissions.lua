--[[
  models/permissions.lua — Central role & permission registry
  =============================================================
  This is the SINGLE source of truth for all roles, permission keys,
  defaults, and sidebar navigation links. Adding a new role or page
  only requires changes to the config tables below.
]]

local DB = "data/permissions.json"
local J = require("modules.json_util")

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
  pages     = "Page Builder",
  campaigns = "Campaigns",
  settings  = "Site Settings",
  agenda    = "Public Agenda",
  profile   = "Profile",
}

-- Default permissions assigned to each role (arrays of permission-key strings).
-- Roles not listed here get an empty set.
local DEFAULTS = {
  admin      = { "dashboard", "users", "articles", "events", "media", "pages", "campaigns", "settings", "agenda", "profile" },
  editor     = { "articles", "events", "media", "pages", "campaigns", "agenda", "profile" },
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
  { perm = "pages",     href = "/admin/pages",     icon = "file-text",label = "Pages" },
  { perm = "campaigns", href = "/admin/campaigns", icon = "target",   label = "Campaigns" },
  { perm = nil,         href = "/admin/roles",     icon = "shield",   label = "Roles",    admin_only = true },
  { perm = nil,         href = "/admin/settings",  icon = "settings", label = "Settings", admin_only = true },
}

-- =========================================================================
-- Internal helpers
-- =========================================================================

local read_file = function() return J.read(DB) end
local write_file = function(data) return J.write(DB, data) end

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
