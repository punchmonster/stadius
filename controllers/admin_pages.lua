--[[ controllers/admin_pages.lua — page builder (admin + editor) ]]
local Pages = require("models.pages")
local Permissions = require("models.permissions")

return {
  before = function(self)
    self.page_title = "admin - pages"
    self.section = "pages"
  end,

  GET = function(self)
    if not Permissions.check(self.db_role, "articles") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action
    self.pages = Pages.list_all()
    if action == "new" then
      self.mode = "new"
    elseif action == "edit" and self.params.id then
      self.mode = "edit"
      self.edit_page = Pages.find_by_id(tonumber(self.params.id))
    else
      self.mode = "list"
    end
    return { render = "admin_pages", layout = "admin_layout" }
  end,

  POST = function(self)
    if not Permissions.check(self.db_role, "articles") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action

    if action == "create" then
      local ok, page = Pages.create(self.params.title, self.params.slug, self.params.content or "", self.params.location or "nav")
      self.message = ok and ("Page created: " .. page.slug) or ("Error: " .. (page or "?"))
    elseif action == "edit" then
      local id = tonumber(self.params.id)
      if id then
        local updates = {}
        if self.params.title    and #self.params.title > 0 then updates.title    = self.params.title end
        if self.params.slug     and #self.params.slug > 0  then updates.slug     = self.params.slug end
        if self.params.location and #self.params.location > 0 then updates.location = self.params.location end
        updates.content = self.params.content or ""
        local _, msg = Pages.update(id, updates)
        self.message = msg
      end
    elseif action == "delete" then
      local id = tonumber(self.params.id)
      if id then
        local _, msg = Pages.delete(id)
        self.message = msg
      end
    end

    self.pages = Pages.list_all()
    self.mode = "list"
    return { render = "admin_pages", layout = "admin_layout" }
  end,
}
