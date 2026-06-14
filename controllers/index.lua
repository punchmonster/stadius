--[[ controllers/index.lua — Home page with article highlights ]]
local Articles = require("models.articles")
local DF = require("modules.date_format")

return {
  before = function(self)
    self.page_title = "home"
    self.section = "home"
    self.submit_url = self:url_for("index")
  end,

  GET = function(self)
    local all = Articles.list_public("date", "desc")
    -- Format dates
    for _, a in ipairs(all) do
      a._created = DF.format(a.created_at)
    end
    self.articles = all
    return { render = "index" }
  end,
}
