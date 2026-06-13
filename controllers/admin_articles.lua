--[[
  controllers/admin_articles.lua — Article editor for admins and editors
  Handles GET (list / create form) and POST (create / edit / delete) for
  "/admin/articles". Only accessible to admins and editors.
  Article operations use numeric id; slug is aesthetic.
--]]

local Articles = require("models.articles")

return {

  --[[
    Guards against unauthorised access. Only admins and editors may enter.

    Self contains the request context.
    Returns a redirect if the user lacks permission.
  --]]
  before = function(self)
    self.page_title = "admin — articles"

    local role = self.session.role
    if role ~= "admin" and role ~= "editor" then
      return { redirect_to = self:url_for("index") }
    end
  end,

  --[[
    Shows the article list or the create/edit form.

    Query params:
      ?action=new         — shows the create form
      ?action=edit&id=X   — shows the edit form for article X

    Sets self.articles, self.edit_article, self.tags_str for the view.

    Returns { render = "admin_articles" }.
  --]]
  GET = function(self)
    local action = self.params.action

    self.articles = Articles.list_all()

    if action == "new" then
      self.mode = "new"
    elseif action == "edit" and self.params.id then
      self.mode = "edit"
      self.edit_article = Articles.find_by_id(tonumber(self.params.id))
      if self.edit_article then
        self.edit_tags = table.concat(self.edit_article.tags or {}, ", ")
      end
    else
      self.mode = "list"
    end

    return { render = "admin_articles" }
  end,

  --[[
    Handles create, edit, and delete actions by article id.

    Supported actions:
      "create" — self.params.title, content, tags, visibility, slug
      "edit"   — self.params.id, title, content, tags, visibility
      "delete" — self.params.id

    Returns { render = "admin_articles" }.
  --]]
  POST = function(self)
    local action = self.params.action
    local role = self.session.role
    if role ~= "admin" and role ~= "editor" then
      return { redirect_to = self:url_for("index") }
    end

    -- Helper: parse comma-separated tags into an array
    local function parse_tags(tags_str)
      local tags = {}
      if tags_str then
        for tag in tags_str:gmatch("[^,]+") do
          local t = tag:match("^%s*(.-)%s*$")
          if #t > 0 then table.insert(tags, t) end
        end
      end
      return tags
    end

    if action == "create" then
      local custom_slug = self.params.slug
      local ok, result = Articles.create(
        self.params.title,
        self.params.content or "",
        self.session.username,
        parse_tags(self.params.tags),
        self.params.visibility or "public",
        custom_slug
      )
      if ok then
        self.message = "Article created: #" .. tostring(result.id) .. " " .. result.slug
      else
        self.message = "Error: " .. result
      end

    elseif action == "edit" then
      local id = tonumber(self.params.id)
      if not id then
        self.message = "Invalid article id"
      else
        local updates = { content = self.params.content or "" }
        if self.params.title and #self.params.title > 0 then
          updates.title = self.params.title
        end
        updates.tags = parse_tags(self.params.tags)
        updates.visibility = self.params.visibility or "public"

        local ok, msg = Articles.update(id, updates)
        self.message = msg
      end

    elseif action == "delete" then
      local id = tonumber(self.params.id)
      if not id then
        self.message = "Invalid article id"
      else
        local ok, msg = Articles.delete(id)
        self.message = msg
      end
    end

    self.articles = Articles.list_all()
    self.mode = "list"

    return { render = "admin_articles" }
  end,

}
