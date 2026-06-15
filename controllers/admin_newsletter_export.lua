--[[ controllers/admin_newsletter_export.lua — CSV export (admin only) ]]
local J = require("modules.json_util")

return {
  before = function(self)
    if self.session.role ~= "admin" then
      return { redirect_to = "/" }
    end
  end,

  GET = function(self)
    local subs = J.read("data/newsletter.json")
    local csv = "Email,Signed Up\n"
    for _, s in ipairs(subs) do
      csv = csv .. s.email .. "," .. (s.signed_up or "") .. "\n"
    end
    ngx.header["Content-Type"] = "text/csv; charset=utf-8"
    ngx.header["Content-Disposition"] = "attachment; filename=\"newsletter_subscribers.csv\""
    ngx.say(csv)
    return ngx.exit(ngx.HTTP_OK)
  end,
}
