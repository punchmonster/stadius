--[[
  controllers/admin.lua — Admin dashboard controller
  Handles GET requests for the "/admin" route.
  Only accessible to users with the "admin" role. Everyone else is bounced to /.
--]]

local User = require("models.user")

return {

  --[[
    Sets page metadata before the admin action.

    Self contains the request context (session, params, url_for, etc.).
    Mutates self.page_title in place. No return value.
  --]]
  before = function(self)
    self.page_title = "admin"
  end,

  --[[
    Renders the admin dashboard if the user has the admin role, otherwise
    redirects to the home page.

    Self contains the request context with self.session.role.
    Sets self.users (all registered users), self.current_user, and self.roles.
    Returns { render = "admin" } or { redirect_to = "/" }.
  --]]
  GET = function(self)
    local role = self.session.role

    -- Only admins may view this page
    if role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end

    -- Load all registered users for display
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
    self.current_user = self.session.username
    self.roles = User.ROLES

    return { render = "admin" }
  end,

}
