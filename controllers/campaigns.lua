--[[ controllers/campaigns.lua — public campaign listing + single page ]]
local Campaigns = require("models.campaigns")

return {
  before = function(self)
    self.page_title = "campaigns"
    self.section = "campaigns"
  end,

  GET = function(self)
    local id = tonumber(self.params.id)
    if id then
      local c = Campaigns.find_by_id(id)
      if not c then return { render = "campaign", status = 404 } end
      c._pct = Campaigns.progress_pct(c)
      self.campaign = c
      self.page_title = c.title
      self.meta_description = c.description:sub(1, 200)
      return { render = "campaign" }
    end
    self.campaigns = Campaigns.list_all()
    self.progress = Campaigns.progress_pct
    return { render = "campaigns" }
  end,
}
