--[[
  models/articles.lua — Flat-file article model
  Stores articles in data/articles.json as an array of objects.
  Each article has a unique numeric id. The slug is aesthetic in the URL.

  Exported functions:
    create(title, content, author, tags, visibility, slug) -> ok, article
    update(id, updates)       -> ok, msg
    delete(id)                -> ok, msg
    find_by_id(id)            -> article or nil
    find_by_slug(slug)        -> article or nil  (legacy, for slug de-dup)
    list_public()             -> array of public articles
    list_all()                -> array of all articles
    increment_view(id)        -> bool
--]]

local DB = "data/articles.json"
local J = require("modules.json_util")
local read_articles = function() return J.read(DB) end
local write_articles = function(data) return J.write(DB, data) end

--[[
  Generates a URL-safe slug from a title string.
  Lowercases, replaces non-alphanumeric chars with hyphens, collapses runs.

  Args:
    title — string, the article title

  Returns:
    string, the generated slug
--]]
local function slugify(title)
  local s = title:lower()
  s = s:gsub("[^a-z0-9%-]", "-")
  s = s:gsub("%-+", "-")
  s = s:gsub("^%-+", ""):gsub("%-+$", "")
  if s == "" then s = "untitled" end
  return s
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--[[
  Creates a new article and appends it to the data file.
  Generates a slug from the title if one is not provided.
  Ensures the slug is unique by appending a numeric suffix if needed.

  Args:
    title      — string, the article title
    content    — string, the markdown content
    author     — string, the username of the author
    tags       — array of strings, e.g. {"lua", "tutorial"}
    visibility — string, "public" or "private"
    slug       — string or nil, optional custom slug

  Returns:
    true, article_table on success
    false, error_message on failure
--]]
local function create(title, content, author, tags, visibility, slug)
  if not title or #title < 1 then
    return false, "Title is required"
  end

  local articles = read_articles()

  -- Auto-increment ID: find the highest existing ID and add 1
  local max_id = 0
  for _, a in ipairs(articles) do
    if a.id and a.id > max_id then max_id = a.id end
  end
  local new_id = max_id + 1

  -- Generate and de-duplicate slug
  local base_slug = slug or slugify(title)
  local final_slug = base_slug
  local suffix = 1
  local slug_exists = true
  while slug_exists do
    slug_exists = false
    for _, a in ipairs(articles) do
      if a.slug == final_slug then
        suffix = suffix + 1
        final_slug = base_slug .. "-" .. tostring(suffix)
        slug_exists = true
        break
      end
    end
  end

  local now = os.date("!%Y-%m-%dT%H:%M:%SZ")

  local article = {
    id = new_id,
    slug = final_slug,
    title = title,
    content = content or "",
    author = author or "unknown",
    tags = tags or {},
    visibility = visibility or "public",
    view_count = 0,
    header_image = nil,
    created_at = now,
    updated_at = now,
  }

  table.insert(articles, article)

  local ok, err = write_articles(articles)
  if not ok then
    return false, err
  end

  return true, article
end

--[[
  Updates an existing article identified by its numeric id.

  Args:
    id      — number, the article id to update
    updates — table, fields to change: title, content, tags, visibility

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function update(id, updates)
  local articles = read_articles()

  for i, a in ipairs(articles) do
    if a.id == id then
      if updates.title then a.title = updates.title end
      if updates.content then a.content = updates.content end
      if updates.tags then a.tags = updates.tags end
      if updates.visibility then a.visibility = updates.visibility end
      if updates.header_image then a.header_image = updates.header_image end
      if updates.slug then a.slug = updates.slug end
      a.updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
      articles[i] = a

      local ok, err = write_articles(articles)
      if not ok then return false, err end
      return true, "Article updated"
    end
  end

  return false, "Article not found"
end

--[[
  Deletes an article by its numeric id.

  Args:
    id — number, the article to delete

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function delete(id)
  local articles = read_articles()

  for i, a in ipairs(articles) do
    if a.id == id then
      table.remove(articles, i)
      local ok, err = write_articles(articles)
      if not ok then return false, err end
      return true, "Article deleted"
    end
  end

  return false, "Article not found"
end

--[[
  Finds a single article by its numeric id.

  Args:
    id — number, the article id

  Returns:
    article_table or nil
--]]
local function find_by_id(id)
  local articles = read_articles()
  for _, a in ipairs(articles) do
    if a.id == id then
      return a
    end
  end
  return nil
end

--[[
  Finds a single article by its slug. Used for de-duplication checks during
  creation; lookup by id is preferred for all other purposes.

  Args:
    slug — string, the article slug

  Returns:
    article_table or nil
--]]
local function find_by_slug(slug)
  local articles = read_articles()
  for _, a in ipairs(articles) do
    if a.slug == slug then
      return a
    end
  end
  return nil
end

local function make_sorter(sort, order)
  local desc = (order ~= "asc")
  if sort == "title" then
    return function(a, b)
      local ta, tb = (a.title or ""):lower(), (b.title or ""):lower()
      if desc then return ta > tb else return ta < tb end
    end
  elseif sort == "views" then
    return function(a, b)
      local va, vb = a.view_count or 0, b.view_count or 0
      if desc then return va > vb else return va < vb end
    end
  elseif sort == "author" then
    return function(a, b)
      local aa, ab = (a.author or ""):lower(), (b.author or ""):lower()
      if desc then return aa > ab else return aa < ab end
    end
  else
    return function(a, b)
      if desc then return a.created_at > b.created_at else return a.created_at < b.created_at end
    end
  end
end

--[[ Lists all public articles, optionally sorted. ]]
local function list_public(sort, order, tag)
  local articles = read_articles()
  local result = {}
  for _, a in ipairs(articles) do
    if a.visibility == "public" then
      if tag then
        local found = false
        for _, t in ipairs(a.tags or {}) do
          if t:lower() == tag:lower() then found = true break end
        end
        if not found then goto continue end
      end
      table.insert(result, a)
    end
    ::continue::
  end
  table.sort(result, make_sorter(sort, order))
  return result
end

--[[
  Increments the view counter on an article identified by id. ... ]]
local function increment_view(id)
  local articles = read_articles()
  for i, a in ipairs(articles) do
    if a.id == id then
      a.view_count = (a.view_count or 0) + 1
      articles[i] = a
      write_articles(articles)
      return true
    end
  end
  return false
end

--[[
  Lists all articles regardless of visibility, newest first.

  Returns:
    array of article tables
--]]
local function list_all(sort, order, tag)
  local articles = read_articles()
  if tag then
    local filtered = {}
    for _, a in ipairs(articles) do
      for _, t in ipairs(a.tags or {}) do
        if t:lower() == tag:lower() then table.insert(filtered, a) break end
      end
    end
    articles = filtered
  end
  table.sort(articles, make_sorter(sort, order))
  return articles
end

return {
  create = create,
  update = update,
  delete = delete,
  find_by_id = find_by_id,
  find_by_slug = find_by_slug,
  list_public = list_public,
  list_all = list_all,
  increment_view = increment_view,
}
