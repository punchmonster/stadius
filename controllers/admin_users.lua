--[[
  controllers/admin_users.lua — Admin user management controller
  Handles GET (list users) and POST (delete / edit) for "/admin/users".
  Only accessible to users with the "admin" role.
  Supports pagination with configurable per-page dropdown.
--]]

local User = require("models.user")

-- Date formatting
local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local function format_date(iso)
  if not iso or iso == "" then return "-" end
  local y, m, d, h, min = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
  if y then
    return MONTHS[tonumber(m)] .. " " .. tonumber(d) .. ", " .. y .. " " .. h .. ":" .. min .. " UTC"
  end
  y, m, d = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if y then
    return MONTHS[tonumber(m)] .. " " .. tonumber(d) .. ", " .. y
  end
  return iso
end

--[[
  Helper: loads all users, slices for pagination, and sets context fields on self.

  Self contains the request context.
  Mutates self.users, self.page, self.total_pages, self.total_users,
  self.per_page, self.valid_steps, self.current_user, self.roles.
--]]
local function load_users(self)
  local file = io.open("data/users.json", "r")
  local all = {}
  if file then
    local content = file:read("*a")
    file:close()
    if content and content ~= "" then
      all = require("lapis.util").from_json(content) or {}
    end
  end

  -- Format dates for display
  for _, u in pairs(all) do
    u._join_date = format_date(u.join_date or u.created_at)
    u._last_login = format_date(u.last_login)
    u._last_pw_change = format_date(u.last_password_change)
    u._sub_start = format_date(u.subscription_start_date)
    u._sub_end = format_date(u.subscription_end_date)
  end

  -- Sort by username
  local keys = {}
  for k in pairs(all) do table.insert(keys, k) end
  table.sort(keys)

  -- Pagination
  local per_page = tonumber(self.params.per_page) or 10
  local valid_steps = { 5, 10, 20, 30, 40, 50 }
  local found = false
  for _, v in ipairs(valid_steps) do if v == per_page then found = true break end end
  if not found then per_page = 10 end

  local total = #keys
  local total_pages = math.max(1, math.ceil(total / per_page))
  local page = tonumber(self.params.page) or 1
  if page < 1 then page = 1 end
  if page > total_pages then page = total_pages end
  local start = (page - 1) * per_page + 1
  local finish = math.min(start + per_page - 1, total)

  -- Build paginated user table
  local paged = {}
  for i = start, finish do
    local username = keys[i]
    paged[username] = all[username]
  end

  self.users = paged
  self.page = page
  self.total_pages = total_pages
  self.total_users = total
  self.per_page = per_page
  self.valid_steps = valid_steps
  self.roles = User.ROLES
  self.current_user = self.session.username
end

return {

  --[[
    Sets page metadata before every action. Guards against non-admin access.

    Self contains the request context.
    Mutates self.page_title. Returns a redirect if the user is not an admin.
  --]]
  before = function(self)
    self.page_title = "admin - users"
    self.section = "users"

    if self.session.role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end
  end,

  --[[
    Loads paginated users and renders the management table.

    Query params:
      ?page=N&per_page=M

    Returns { render = "admin_users" }.
  --]]
  GET = function(self)
    load_users(self)
    return { render = "admin_users", layout = "admin_layout" }
  end,

  --[[
    Handles delete and edit actions, then re-renders with pagination.

    Supported actions:
      "delete" — self.params.target_user
      "edit"   — self.params.target_user, new_role, new_password, new_email,
                 new_phone, sub_active, sub_start, sub_end

    Returns { render = "admin_users" }.
  --]]
  POST = function(self)
    if self.session.role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end

    local action = self.params.action
    local target = self.params.target_user

    if action == "delete" then
      if target == self.session.username then
        self.message = "You cannot delete your own account."
      else
        local ok, msg = User.delete_user(target)
        self.message = msg
      end

    elseif action == "edit" then
      -- Parse array-style params: role[username], email[username], etc.
      -- Lapis auto-parses these into tables keyed by username.
      local roles     = self.params.role or {}
      local emails    = self.params.email or {}
      local phones    = self.params.phone or {}
      local passwords = self.params.password or {}
      local sub_actives = self.params.sub_active or {}
      local sub_starts  = self.params.sub_start or {}
      local sub_ends    = self.params.sub_end or {}

      -- Collect all usernames that appear in any field
      local usernames = {}
      for k in pairs(roles) do usernames[k] = true end
      for k in pairs(emails) do usernames[k] = true end
      for k in pairs(phones) do usernames[k] = true end
      for k in pairs(passwords) do usernames[k] = true end
      for k in pairs(sub_actives) do usernames[k] = true end
      for k in pairs(sub_starts) do usernames[k] = true end
      for k in pairs(sub_ends) do usernames[k] = true end

      local updated = 0
      for username in pairs(usernames) do
        local function nil_if_empty(s)
          if s == nil or s == "" then return nil end
          return s
        end

        local role_val = nil_if_empty(roles[username])
        local pw_val   = nil_if_empty(passwords[username])

        local sub_active = nil_if_empty(sub_actives[username])
        if sub_active == "true" then
          sub_active = true
        elseif sub_active == "false" then
          sub_active = false
        else
          sub_active = nil
        end

        -- Only call update if at least one field changed
        local has_change = role_val or pw_val or
                           nil_if_empty(emails[username]) or
                           nil_if_empty(phones[username]) or
                           sub_active or
                           nil_if_empty(sub_starts[username]) or
                           nil_if_empty(sub_ends[username])

        if has_change then
          User.update_user(username, role_val, pw_val,
                           nil_if_empty(emails[username]),
                           nil_if_empty(phones[username]),
                           sub_active,
                           nil_if_empty(sub_starts[username]),
                           nil_if_empty(sub_ends[username]))
          updated = updated + 1
        end
      end

      if updated > 0 then
        self.message = "Updated " .. tostring(updated) .. " user(s)."
      else
        self.message = "No changes detected."
      end
    end

    load_users(self)
    return { render = "admin_users", layout = "admin_layout" }
  end,

}
