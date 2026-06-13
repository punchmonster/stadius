local lapis = require("lapis")
local app = lapis.Application()
app:enable("etlua")
app:match("test", "/test", function(self)
  return { render = "test_build_url" }
end)
return app
