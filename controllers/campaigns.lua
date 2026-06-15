--[[ controllers/campaigns.lua — public campaign listing ]]
local Campaigns = require("models.campaigns")

return {
  before = function(self)
    self.page_title = "campaigns"
    self.section = "campaigns"
  end,
  GET = function(self)
    self.campaigns = Campaigns.list_all()
    self.progress = Campaigns.progress_pct
    return { render = "campaigns" }
  end,
}
