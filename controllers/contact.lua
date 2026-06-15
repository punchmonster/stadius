--[[ controllers/contact.lua — contact page with info from settings ]]
local Settings = require("models.settings")

return {
  before = function(self)
    self.page_title = "contact"
    self.section = "contact"
    self.settings = Settings.get()
    self.meta_description = "Get in touch with " .. (self.settings.site_name or "us") .. "."
  end,
  GET = function(self)
    return { render = "contact" }
  end,
}
