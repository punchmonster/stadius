--[[ controllers/admin_media.lua — Media library for admins and editors ]]
local Media = require("models.media")
local Permissions = require("models.permissions")

return {
  before = function(self)
    self.page_title = "admin - media"
    self.section = "media"
  end,

  GET = function(self)
    if not Permissions.check(self.db_role, "media") then
      return { redirect_to = self:url_for("index") }
    end
    self.media = Media.list_all()
    return { render = "admin_media", layout = "admin_layout" }
  end,

  POST = function(self)
    if not Permissions.check(self.db_role, "media") then
      return { redirect_to = self:url_for("index") }
    end
    if self.params.action == "delete" then
      local deleted = 0
      -- self.params.ids may be a single value or a table (multiple checkboxes)
      local ids = self.params.ids
      if ids then
        if type(ids) == "table" then
          for _, id_str in ipairs(ids) do
            local id = tonumber(id_str)
            if id then
              local m = Media.find_by_id(id)
              if m then
                os.remove("static/uploads/media/" .. m.filename)
                Media.delete(id)
                deleted = deleted + 1
              end
            end
          end
        else
          local id = tonumber(ids)
          if id then
            local m = Media.find_by_id(id)
            if m then
              os.remove("static/uploads/media/" .. m.filename)
              Media.delete(id)
              deleted = 1
            end
          end
        end
      end
      self.message = deleted > 0 and ("Deleted " .. deleted .. " image(s).") or "No images selected."
    end
    self.media = Media.list_all()
    return { render = "admin_media", layout = "admin_layout" }
  end,
}
