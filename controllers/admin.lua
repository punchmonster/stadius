--[[
  controllers/admin.lua — Admin dashboard controller
  Handles GET requests for the "/admin" route.
  Only accessible to users with the "admin" role. Everyone else is bounced to /.
--]]

local User = require("models.user")

return {

  --[[
    Sets page metadata before the admin action.

    Self contains the request context.
    Mutates self.page_title in place. No return value.
  --]]
  before = function(self)
    self.page_title = "admin"
    self.section = "dashboard"
  end,

  --[[
    Renders the admin dashboard if the user is an admin, otherwise redirects
    to the home page. Shows a summary count of non-admin registered users.

    Self contains the request context with self.session.role.
    Sets self.user_count (number of registered non-admin users).

    Returns { render = "admin" } or { redirect_to = "/" }.
  --]]
  GET = function(self)
    local role = self.session.role

    if role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end

    -- Count registered users excluding admins
    local file = io.open("data/users.json", "r")
    local count = 0
    if file then
      local content = file:read("*a")
      file:close()
      if content and content ~= "" then
        local users = require("lapis.util").from_json(content) or {}
        for _, u in pairs(users) do
          local r = u.role or User.DEFAULT_ROLE
          if r ~= "admin" then
            count = count + 1
          end
        end
      end
    end

    self.user_count = count
    self.current_user = self.session.username

    return { render = "admin", layout = "admin_layout" }
  end,

}
