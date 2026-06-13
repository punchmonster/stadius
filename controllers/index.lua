--[[
  controllers/index.lua — Home page controller
  Handles GET requests for the "/" route.
--]]

return {

  --[[
    Sets page metadata before every action on this controller.

    Self contains the request context (params, session, url_for, etc.).
    Mutates self.page_title and self.submit_url in place. No return value.
  --]]
  before = function(self)
    self.page_title = "home"
    self.submit_url = self:url_for("index")
  end,

  --[[
    Handles GET requests to the home page.

    Self contains the request context.
    Returns { render = "index" } to render views/index.etlua.
  --]]
  GET = function(self)
    return { render = "index" }
  end,

}
