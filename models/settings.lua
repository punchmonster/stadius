--[[ models/settings.lua — simple key-value site settings store ]]
local DB = "data/settings.json"
local J = require("modules.json_util")

-- Defaults applied on first read if no file exists.
local DEFAULTS = {
  site_name   = "Stadius",
  timezone    = "UTC",
  favicon     = "",
  logo        = "",
  contact_email = "",
  contact_phone = "",
  contact_address = "",
  contact_twitter   = "",
  contact_github    = "",
  contact_facebook  = "",
  contact_instagram = "",
  contact_whatsapp  = "",
  show_contact_footer = false,
  show_campaigns_home = false,
  show_newsletter_home = false,
  footer_links = "[]",
  disabled_plugins = "[]",
}

local function get()
  local data = J.read(DB)
  if not data then data = {} end
  -- Merge defaults for missing keys
  for k, v in pairs(DEFAULTS) do
    if data[k] == nil then data[k] = v end
  end
  return data
end

local function save(updates)
  local data = get()
  for k, v in pairs(updates) do data[k] = v end
  return J.write(DB, data)
end

return { get = get, save = save }
