--[[ controllers/newsletter.lua — newsletter signup + CSV export ]]
local J = require("modules.json_util")

return {
  -- Signup
  POST = function(self)
    local email = self.params.email
    if email and #email > 5 and email:match("@") then
      local list = J.read("data/newsletter.json")
      table.insert(list, { email = email, signed_up = os.date("!%Y-%m-%dT%H:%M:%SZ") })
      J.write("data/newsletter.json", list)
    end
    return { redirect_to = "/?signed_up=1" }
  end,
}
