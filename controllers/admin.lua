--[[ controllers/admin.lua — dashboard with stats ]]
local Articles = require("models.articles")
local Campaigns = require("models.campaigns")
local Permissions = require("models.permissions")
local J = require("modules.json_util")
local DF = require("modules.date_format")

return {
  before = function(self)
    self.page_title = "admin"
    self.section = "dashboard"
  end,

  GET = function(self)
    if not Permissions.check(self.db_role, "dashboard") then
      return { redirect_to = self:url_for("index") }
    end

    self.current_user = self.session.username

    -- Recent articles
    local all_articles = Articles.list_all("date", "desc")
    self.recent_articles = {}
    for i = 1, math.min(5, #all_articles) do
      local a = all_articles[i]
      a._created = DF.format(a.created_at)
      table.insert(self.recent_articles, a)
    end

    -- User stats
    local users = J.read("data/users.json")
    local total_users = 0
    local non_admin = 0
    for _ in pairs(users) do total_users = total_users + 1 end
    for _, u in pairs(users) do
      if (u.role or "reader") ~= "admin" then non_admin = non_admin + 1 end
    end
    self.total_users = total_users
    self.non_admin_users = non_admin

    -- User signups by month (last 6 months)
    local months = {}
    local now = os.date("*t")
    for i = 5, 0, -1 do
      local m = now.month - i
      local y = now.year
      if m < 1 then m = m + 12; y = y - 1 end
      table.insert(months, { year = y, month = m, key = string.format("%d-%02d", y, m) })
    end
    self.signup_months = {}
    local signup_counts = {}
    for _, m in ipairs(months) do
      signup_counts[m.key] = 0
      table.insert(self.signup_months, { label = os.date("%b", os.time{year=m.year, month=m.month, day=1}), key = m.key })
    end
    local max_count = 1
    for _, u in pairs(users) do
      if u.created_at then
        local y, m = u.created_at:match("^(%d%d%d%d)%-(%d%d)")
        if y and m then
          local key = y .. "-" .. m
          if signup_counts[key] then
            signup_counts[key] = signup_counts[key] + 1
            if signup_counts[key] > max_count then max_count = signup_counts[key] end
          end
        end
      end
    end
    self.signup_counts = signup_counts
    self.signup_max = max_count

    -- Newsletter
    self.newsletter_count = #(J.read("data/newsletter.json"))

    -- Campaigns
    local all_campaigns = Campaigns.list_all()
    self.campaigns = {}
    for i = 1, math.min(5, #all_campaigns) do
      local c = all_campaigns[i]
      c._pct = Campaigns.progress_pct(c)
      table.insert(self.campaigns, c)
    end

    return { render = "admin", layout = "admin_layout" }
  end,
}
