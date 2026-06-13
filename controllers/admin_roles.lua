--[[
  controllers/admin_roles.lua — Role permissions editor
  GET shows a matrix of roles vs permissions. POST saves changes.
  Only accessible to admins.
--]]

local Permissions = require("models.permissions")

return {

  before = function(self)
    self.page_title = "admin - roles"
    self.section = "roles"
    self.is_admin = true
    self.permissions = Permissions.get(self.db_role or "reader")
  end,

  --[[
    Shows the permission matrix. Admin only.
  --]]
  GET = function(self)
    if self.db_role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end
    self.roles = Permissions.ROLES
    self.perms_data = Permissions.get_all()
    self.perm_keys = Permissions.PERMISSION_KEYS
    return { render = "admin_roles", layout = "admin_layout" }
  end,

  --[[
    Saves permission changes for one role at a time.
    self.params: role, and checked permission names as individual params.
  --]]
  POST = function(self)
    if self.db_role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end
    local role = self.params.role
    if not role then
      self.message = "No role specified."
    else
      -- Collect which permissions are checked for this role
      local perms = {}
      for key, _ in pairs(Permissions.PERMISSION_KEYS) do
        if self.params[key] == "on" then
          table.insert(perms, key)
        end
      end

      local ok = Permissions.set(role, perms)
      if ok then
        self.message = "Permissions saved for " .. role .. "."
      else
        self.message = "Failed to save permissions."
      end
    end

    self.roles = Permissions.ROLES
    self.perms_data = Permissions.get_all()
    self.perm_keys = Permissions.PERMISSION_KEYS
    return { render = "admin_roles", layout = "admin_layout" }
  end,

}
