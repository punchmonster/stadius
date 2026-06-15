--[[ controllers/admin_settings.lua — site settings (admin only) ]]
local Settings = require("models.settings")
local Permissions = require("models.permissions")

return {
  before = function(self)
    self.page_title = "admin - settings"
    self.section = "settings"
  end,

  GET = function(self)
    if self.db_role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end
    self.settings = Settings.get()
    return { render = "admin_settings", layout = "admin_layout" }
  end,

  POST = function(self)
    if self.db_role ~= "admin" then
      return { redirect_to = self:url_for("index") }
    end

    local updates = {}
    for _, key in ipairs({"site_name", "timezone", "contact_email", "contact_phone",
                           "contact_address", "contact_twitter", "contact_github",
                           "contact_facebook", "contact_instagram", "contact_whatsapp"}) do
      if self.params[key] ~= nil then updates[key] = self.params[key] end
    end
    -- Only update checkboxes from the form that was submitted
    local form = self.params.form_id
    if form == "general" then
      updates.show_campaigns_home = (self.params.show_campaigns_home == "true")
      updates.show_header_search = (self.params.show_header_search == "true")
    elseif form == "contact" then
      updates.show_contact_footer = (self.params.show_contact_footer == "true")
    elseif form == "newsletter" then
      updates.show_newsletter_home = (self.params.show_newsletter_home == "true")
    elseif form == "footer_links" then
      local raw = self.params.fl_raw or ""
      local links = {}
      for line in raw:gmatch("[^\r\n]+") do
        local label, url = line:match("^%s*(.-)%s*|%s*(.-)%s*$")
        if label and url and label ~= "" then
          table.insert(links, {label = label, url = url})
        end
      end
      if #links == 0 then updates.footer_links = "[]"
      else updates.footer_links = require("lapis.util").to_json(links) end

    elseif form == "plugins" then
      local all_plugins = require("plugins.manifest")
      local disabled = {}
      for _, name in ipairs(all_plugins) do
        if self.params["plugin_" .. name] ~= "true" then
          table.insert(disabled, name)
        end
      end
      if #disabled == 0 then updates.disabled_plugins = "[]"
      else updates.disabled_plugins = require("lapis.util").to_json(disabled) end
    end

    -- Handle favicon upload
    local fav = self.params.favicon
    if fav and fav.content and #fav.content > 0 then
      local Image = require("modules.image")
      local name, _, err = Image.process(fav.content, fav.filename or "favicon")
      if name then
        updates.favicon = name
      else
        self.message = "Favicon: " .. (err or "upload failed")
      end
    end

    -- Handle logo upload
    local logo = self.params.logo
    if logo and logo.content and #logo.content > 0 then
      local Image = require("modules.image")
      local name, _, err = Image.process(logo.content, logo.filename or "logo")
      if name then
        updates.logo = name
      elseif not self.message then
        self.message = "Logo: " .. (err or "upload failed")
      end
    end

    Settings.save(updates)
    if not self.message then self.message = "Settings saved." end
    self.settings = Settings.get()
    return { render = "admin_settings", layout = "admin_layout" }
  end,
}
