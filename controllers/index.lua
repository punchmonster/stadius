--[[ controllers/index.lua — Home page with article highlights and campaign sidebar ]]
local Articles = require("models.articles")
local Campaigns = require("models.campaigns")
local Settings = require("models.settings")
local DF = require("modules.date_format")

return {
  before = function(self)
    self.page_title = "home"
    self.section = "home"
    self.submit_url = self:url_for("index")
  end,

  GET = function(self)
    local all = Articles.list_public("date", "desc")
    for _, a in ipairs(all) do
      a._created = DF.format(a.created_at)
    end
    self.articles = all
    self.campaigns = Campaigns.list_all()
    self.campaign_progress = Campaigns.progress_pct
    self.site = Settings.get()
    return { render = "index" }
  end,
}
