--[[
  controllers/articles.lua — Public article listing and viewing
  Handles GET "/articles" (list) and GET "/articles/:id/:slug" (single article).
  Article lookup is by numeric id; the slug is purely aesthetic in the URL.
--]]

local Articles = require("models.articles")
local Markdown = require("modules.markdown")

return {

  --[[
    Sets page metadata.

    Self contains the request context.
    Mutates self.page_title. No return value.
  --]]
  before = function(self)
    self.page_title = "articles"
  end,

  --[[
    Lists public articles (newest first) or shows a single article by id.
    Admins and editors see private articles in the listing and on single view.

    Returns { render = "articles" } for listing, { render = "article" } for single.
  --]]
  GET = function(self)
    local id = tonumber(self.params.id)

    if id then
      -- Single article view — lookup by id, slug is ignored
      local article = Articles.find_by_id(id)
      if not article then
        return { render = "article", status = 404 }
      end

      -- Private articles visible only to author, admins, or editors
      local role = self.session.role
      local username = self.session.username
      if article.visibility == "private"
         and role ~= "admin"
         and role ~= "editor"
         and article.author ~= username then
        return { render = "article", status = 404 }
      end

      self.article = article
      self.article_html = Markdown.to_html(article.content)
      self.page_title = article.title
      self.can_edit = (role == "admin" or role == "editor")

      -- View counting disabled pending async implementation
      -- Articles.increment_view(id)

      return { render = "article" }
    else
      -- List view
      local role = self.session.role
      if role == "admin" or role == "editor" then
        self.articles = Articles.list_all()
      else
        self.articles = Articles.list_public()
      end

      return { render = "articles" }
    end
  end,

}
