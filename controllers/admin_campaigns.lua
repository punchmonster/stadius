--[[ controllers/admin_campaigns.lua — campaign editor (admin + editor) ]]
local Campaigns = require("models.campaigns")
local Permissions = require("models.permissions")

return {
  before = function(self)
    self.page_title = "admin - campaigns"
    self.section = "campaigns"
  end,

  GET = function(self)
    if not Permissions.check(self.db_role, "articles") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action
    self.campaigns = Campaigns.list_all()
    if action == "new" then
      self.mode = "new"
    elseif action == "edit" and self.params.id then
      self.mode = "edit"
      self.edit_campaign = Campaigns.find_by_id(tonumber(self.params.id))
    else
      self.mode = "list"
    end
    return { render = "admin_campaigns", layout = "admin_layout" }
  end,

  POST = function(self)
    if not Permissions.check(self.db_role, "articles") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action

    if action == "create" then
      local ok, c = Campaigns.create(self.params.title, self.params.description, self.params.goal_type, self.params.goal_target, self.params.goal_current)
      self.message = ok and ("Campaign created: #" .. c.id) or ("Error: " .. (c or "?"))
    elseif action == "edit" then
      local id = tonumber(self.params.id)
      if id then
        local u = {}
        if self.params.title and #self.params.title > 0 then u.title = self.params.title end
        u.description = self.params.description or ""
        u.goal_type = self.params.goal_type
        u.goal_target = self.params.goal_target
        u.goal_current = self.params.goal_current
        local _, msg = Campaigns.update(id, u)
        self.message = msg
      end
    elseif action == "delete" then
      local id = tonumber(self.params.id)
      if id then
        local _, msg = Campaigns.delete(id)
        self.message = msg
      end
    end

    self.campaigns = Campaigns.list_all()
    self.mode = "list"
    return { render = "admin_campaigns", layout = "admin_layout" }
  end,
}
