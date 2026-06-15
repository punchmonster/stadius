--[[  controllers/admin_articles.lua — Article editor for admins and editors  ]]
local Articles = require("models.articles")
local Permissions = require("models.permissions")
local DF = require("modules.date_format")
local Image = require("modules.image")
local H = require("modules.helpers")

local function paginate(self)
  local per_page = tonumber(self.params.per_page) or 10
  local valid_steps = { 5, 10, 20, 30, 40, 50 }
  local found = false
  for _, v in ipairs(valid_steps) do if v == per_page then found = true break end end
  if not found then per_page = 10 end
  local all = Articles.list_all(self.params.sort, self.params.order, self.params.tag, self.params.q)
  self.sort = self.params.sort or "date"
  self.order = self.params.order or "desc"
  self.tag_filter = self.params.tag
  self.search_query = self.params.q
  local total = #all
  local total_pages = math.max(1, math.ceil(total / per_page))
  local page = tonumber(self.params.page) or 1
  if page < 1 then page = 1 elseif page > total_pages then page = total_pages end
  local start = (page - 1) * per_page + 1
  local finish = math.min(start + per_page - 1, total)
  self.articles = {}
  for i = start, finish do
    local a = all[i]
    a._created = DF.format(a.created_at)
    a._updated = DF.format(a.updated_at)
    table.insert(self.articles, a)
  end
  self.page = page
  self.total_pages = total_pages
  self.total_articles = total
  self.per_page = per_page
  self.valid_steps = valid_steps
end

return {
  before = function(self)
    self.page_title = "admin - articles"
    self.section = "articles"
  end,

  GET = function(self)
    if not Permissions.check(self.db_role, "articles") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action
    paginate(self)
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
    return { render = "admin_articles", layout = "admin_layout" }
  end,

  POST = function(self)
    if not Permissions.check(self.db_role, "articles") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action

    if action == "create" then
      local ok, result = Articles.create(
        self.params.title, self.params.content or "",
        self.session.username, H.parse_tags(self.params.tags),
        self.params.visibility or "public", self.params.slug
      )
      self.message = ok and ("Article created: #" .. tostring(result.id)) or ("Error: " .. result)

    elseif action == "edit" then
      local id = tonumber(self.params.id)
      if id then
        local updates = { content = self.params.content or "" }
        if self.params.title and #self.params.title > 0 then updates.title = self.params.title end
        updates.tags = H.parse_tags(self.params.tags)
        updates.visibility = self.params.visibility or "public"
        local _, msg = Articles.update(id, updates)
        self.message = msg
      else self.message = "Invalid article id" end

    elseif action == "delete" then
      local id = tonumber(self.params.id)
      if id then
        local _, msg = Articles.delete(id)
        self.message = msg
      else self.message = "Invalid article id" end

    -- Image actions --
    elseif action == "upload_image" then
      local name = Image.save_upload(self.params, self.session.username)
      local id = tonumber(self.params.id)
      if name and id then
        Articles.update(id, { header_image = name })
        self.message = "Image uploaded."
      elseif not name then
        self.message = "Upload failed — check file type (JPG/PNG/WebP only)."
      end

    elseif action == "remove_image" then
      local id = tonumber(self.params.id)
      if id then Articles.update(id, { header_image = "" }) end
      self.message = "Image removed."

    elseif action == "select_image" then
      local id = tonumber(self.params.id)
      if id and self.params.filename then
        Articles.update(id, { header_image = self.params.filename })
        self.message = "Header image set from library."
      end
    end

    paginate(self)
    self.mode = "list"
    return { render = "admin_articles", layout = "admin_layout" }
  end,
}
