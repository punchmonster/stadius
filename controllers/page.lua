--[[ controllers/page.lua — serves custom pages at /page/:slug ]]
local Pages = require("models.pages")
local Markdown = require("modules.markdown")

return {
  before = function(self)
    self.page_title = self.params.slug or "page"
  end,

  GET = function(self)
    local page = Pages.find_by_slug(self.params.slug)
    if not page then
      return { render = "page", status = 404 }
    end
    self.page_title = page.title
    self.meta_description = page.content:gsub("<[^>]+>", ""):gsub("\n", " "):sub(1, 200)
    local hooks = require("modules.hooks")
    if page.content_type == "markdown" then
      self.page_html = Markdown.to_html(page.content)
    else
      self.page_html = hooks.render_shortcodes(page.content)
    end
    self.custom_page = page
    return { render = "page" }
  end,
}
