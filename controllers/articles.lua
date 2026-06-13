--[[
  controllers/articles.lua — Articles page controller
  Handles GET requests for the "/articles" route.
  Displays a list of articles (currently static placeholder data).
--]]

return {

  --[[
    before: Runs before every action on this controller.
    Sets page metadata used by the layout template.
  --]]
  before = function(self)
    -- Page title shown in browser tab / layout header
    self.page_title = "articles"

    -- Build the URL for form submissions / navigation
    self.submit_url = self:url_for("articles")
  end,

  --[[
    GET: Handles GET requests to the articles page.
    Builds a list of article data and renders the "articles" template.
  --]]
  GET = function(self)
    -- Placeholder article data — in production this would come from a database
    self.articles = {
      {
        id = 1,
        title = "Getting Started with Lapis",
        author = "Stadius Team",
        summary = "Learn how to build web applications with the Lapis framework on OpenResty.",
        date = "2026-06-01"
      },
      {
        id = 2,
        title = "Lua Web Development Best Practices",
        author = "Stadius Team",
        summary = "Tips and patterns for writing clean, maintainable Lua web applications.",
        date = "2026-06-05"
      },
      {
        id = 3,
        title = "Understanding MVC in Lapis",
        author = "Stadius Team",
        summary = "A deep dive into the Model-View-Controller pattern as implemented in Lapis.",
        date = "2026-06-10"
      },
    }

    return { render = "articles" }
  end,

}
