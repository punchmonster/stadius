--[[
  controllers/admin.lua — Admin dashboard controller
  Handles GET requests for the "/admin" route.
  Only accessible to users with the "admin" role. Everyone else is bounced to /.
--]]

local User = require("models.user")
local Permissions = require("models.permissions")

return {

  --[[
    Sets page metadata. Guards access via permissions.

    Self contains the request context.
  --]]
  before = function(self)
    self.page_title = "admin"
    self.section = "dashboard"
  end,

  --[[
    Renders the admin dashboard if the user has dashboard permission.

    Returns { render = "admin", layout = "admin_layout" } or redirect.
  --]]
  GET = function(self)
    if not Permissions.check(self.db_role, "dashboard") then
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
