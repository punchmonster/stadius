--[[
  controllers/articles.lua — Public article listing and viewing
  Handles GET "/articles" (list) and GET "/articles/:id/:slug" (single article).
  Article lookup is by numeric id; the slug is purely aesthetic in the URL.
--]]

local Articles = require("models.articles")
local Markdown = require("modules.markdown")
local DF = require("modules.date_format")

return {

  --[[
    Sets page metadata.

    Self contains the request context.
    Mutates self.page_title. No return value.
  --]]
  before = function(self)
    self.page_title = "articles"
    self.section = "articles"
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
      local role = self.db_role
      local username = self.session.username
      if article.visibility == "private"
         and role ~= "admin"
         and role ~= "editor"
         and article.author ~= username then
        return { render = "article", status = 404 }
      end

      article._created = DF.format(article.created_at)
      article._updated = DF.format(article.updated_at)

      self.article = article
      self.article_html = Markdown.to_html(article.content)
      self.page_title = article.title
      self.can_edit = (role == "admin" or role == "editor")

      -- View counting disabled pending async implementation
      -- Articles.increment_view(id)

      return { render = "article" }
    else
      -- List view with pagination (8 per page)
      local role = self.db_role
      local sort = self.params.sort or "date"
      local order = self.params.order or "desc"
      local tag = self.params.tag
      local all
      if role == "admin" or role == "editor" then
        all = Articles.list_all(sort, order, tag)
      else
        all = Articles.list_public(sort, order, tag)
      end
      self.sort = sort
      self.order = order
      self.tag_filter = tag

      local per_page = 8
      local page = tonumber(self.params.page) or 1
      local total = #all
      local total_pages = math.max(1, math.ceil(total / per_page))
      if page < 1 then page = 1 end
      if page > total_pages then page = total_pages end
      local start = (page - 1) * per_page + 1
      local finish = math.min(start + per_page - 1, total)

      self.articles = {}
      for i = start, finish do
        local a = all[i]
        a._created = DF.format(a.created_at)
        table.insert(self.articles, a)
      end
      self.page = page
      self.total_pages = total_pages
      self.total_articles = total
      self.per_page = per_page

      return { render = "articles" }
    end
  end,

}
