--[[
  controllers/admin_users.lua — Admin user management controller
  Handles GET (list users) and POST (delete / edit) for "/admin/users".
  Only accessible to users with the "admin" role.
--]]

local User = require("models.user")

return {

  --[[
    Sets page metadata before every action. Guards against non-admin access.

    Self contains the request context.
    Mutates self.page_title. Returns a redirect if the user is not an admin.
  --]]
  before = function(self)
    self.page_title = "admin — users"

    if self.session.role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end
  end,

  --[[
    Loads all registered users and renders the management table.

    Self contains the request context.
    Sets self.users, self.roles, and self.current_user.

    Returns { render = "admin_users" }.
  --]]
  GET = function(self)
    local file = io.open("data/users.json", "r")
    local users = {}
    if file then
      local content = file:read("*a")
      file:close()
      if content and content ~= "" then
        users = require("lapis.util").from_json(content) or {}
      end
    end

    self.users = users
    self.roles = User.ROLES
    self.current_user = self.session.username

    return { render = "admin_users" }
  end,

  --[[
    Handles delete and edit actions from the user management form.

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
      -- Helper: treat empty strings as nil (leave field unchanged)
      local function nil_if_empty(s)
        if s == nil or s == "" then return nil end
        return s
      end

      local new_role     = nil_if_empty(self.params.new_role)
      local new_password = nil_if_empty(self.params.new_password)
      local new_email    = nil_if_empty(self.params.new_email)
      local new_phone    = nil_if_empty(self.params.new_phone)

      -- Subscription active: dropdown sends "true", "false", or "" (no change)
      local sub_active   = nil_if_empty(self.params.sub_active)
      if sub_active == "true" then
        sub_active = true
      elseif sub_active == "false" then
        sub_active = false
      else
        sub_active = nil
      end

      local sub_start    = nil_if_empty(self.params.sub_start)
      local sub_end      = nil_if_empty(self.params.sub_end)

      local ok, msg = User.update_user(target, new_role, new_password, new_email, new_phone,
                                        sub_active, sub_start, sub_end)
      self.message = msg
    end

    -- Reload the user list after the mutation
    local file = io.open("data/users.json", "r")
    local users = {}
    if file then
      local content = file:read("*a")
      file:close()
      if content and content ~= "" then
        users = require("lapis.util").from_json(content) or {}
      end
    end

    self.users = users
    self.roles = User.ROLES
    self.current_user = self.session.username

    return { render = "admin_users" }
  end,

}
