--[[
  controllers/index.lua — Home page controller
  Handles GET requests for the root "/" route.
  Returns the index view with a welcome message.
--]]

return {

  --[[
    before: Runs before every action on this controller.
    Sets page metadata used by the layout template.
  --]]
  before = function(self)
    -- Page title shown in browser tab / layout header
    self.page_title = "home"

    -- Build the form submission URL for use in templates
    self.submit_url = self:url_for("index")
  end,

  --[[
    GET: Handles GET requests to the home page.
    Renders the "index" etlua template.
  --]]
  GET = function(self)
    -- Data passed to the view template
    self.welcome_message = "Welcome to Stadius"
    self.description = "A Lapis-powered web application."

    return { render = "index" }
  end,

}
