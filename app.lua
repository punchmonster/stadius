--[[
  app.lua — Stadius application entry point
  Defines routes and loads controllers.
--]]

local lapis = require("lapis")
local respond_to = require("lapis.application").respond_to

local app = lapis.Application()

-- Enable etlua templating
app:enable("etlua")

-- Global before_filter: refresh role and permissions from DB on every request.
-- This ensures role changes take effect immediately without re-login.
app:before_filter(function(self)
  if self.session.username then
    local User = require("models.user")
    local Permissions = require("models.permissions")
    local user = User.find_by_username(self.session.username)
    if user then
      self.db_role = user.role
      self.permissions = Permissions.get(user.role)
      self.is_admin = (user.role == "admin")
    end
    -- Make icon helper available in all templates
    self.icon = require("modules.icon").icon
  end
end)

-- ---------------------------------------------------------------------------
-- Load Controllers
-- ---------------------------------------------------------------------------
local index_controller        = require("controllers.index")
local login_controller        = require("controllers.login")
local admin_controller        = require("controllers.admin")
local admin_users_controller  = require("controllers.admin_users")
local admin_articles_controller = require("controllers.admin_articles")
local admin_events_controller   = require("controllers.admin_events")
local admin_roles_controller   = require("controllers.admin_roles")
local admin_media_controller   = require("controllers.admin_media")
local profile_controller      = require("controllers.profile")
local articles_controller     = require("controllers.articles")
local events_controller       = require("controllers.events")

-- ---------------------------------------------------------------------------
-- Routes
-- ---------------------------------------------------------------------------

-- Home page
app:match("index", "/", respond_to(index_controller))

-- Login page — GET renders form, POST processes login/signup
app:match("login", "/login", respond_to(login_controller))

-- User profile — requires login, non-admins land here after signup/login
app:match("profile", "/profile", respond_to(profile_controller))

-- Public article listing
app:match("articles", "/articles", respond_to(articles_controller))

-- Single article view — lookup by numeric id only
app:match("article", "/articles/:id", respond_to(articles_controller))

-- Legacy / aesthetic URL with slug — also resolves by id, slug is ignored
app:match("article_slug", "/articles/:id/:slug", respond_to(articles_controller))

-- Admin dashboard — protected by role check in the controller
app:match("admin", "/admin", respond_to(admin_controller))

-- Admin user management subpage — protected by role check
app:match("admin_users", "/admin/users", respond_to(admin_users_controller))

-- Admin article editor — protected by role check (admin + editor)
app:match("admin_articles", "/admin/articles", respond_to(admin_articles_controller))

-- Admin event editor — protected by role check (admin + editor)
app:match("admin_events", "/admin/events", respond_to(admin_events_controller))

-- Admin role permissions — admin only
app:match("admin_roles", "/admin/roles", respond_to(admin_roles_controller))

-- Admin media library
app:match("admin_media", "/admin/media", respond_to(admin_media_controller))

-- Public agenda page (listing)
app:match("agenda", "/agenda", respond_to(events_controller))

-- Single event page
app:match("event", "/agenda/:id", respond_to(events_controller))

-- Shared image upload handler (used by both article and event upload forms)
local function handle_upload(self, redirect_base, id_param, model)
  local id = tonumber(self.params[id_param])

  -- Remove action: clear header_image but keep file + metadata
  if self.params.action == "remove" then
    if id then model.update(id, { header_image = "" }) end
    return { redirect_to = redirect_base .. "?action=edit&id=" .. (self.params[id_param] or "") }
  end

  -- Upload action
  local file = self.params.header_image
  if file and file.content and #file.content > 0 then
    local Image = require("modules.image")
    local name, file_size, err = Image.process(file.content, file.filename)
    if not name then
      -- Pass error back via session (simplified: use a query param)
      return { redirect_to = redirect_base .. "?action=edit&id=" .. (self.params[id_param] or "")
               .. "&error=" .. (err or "upload_failed") }
    end
    local Media = require("models.media")
    local tags = {}
    if self.params.image_tags then
      for tag in self.params.image_tags:gmatch("[^,]+") do
        local t = tag:match("^%s*(.-)%s*$")
        if #t > 0 then table.insert(tags, t) end
      end
    end
    Media.create(name, self.params.image_title, self.params.image_alt,
                 self.params.image_credit, tags, self.session.username, file_size or #file.content)
    if id then model.update(id, { header_image = name }) end
  end
  return { redirect_to = redirect_base .. "?action=edit&id=" .. (self.params[id_param] or "") }
end

-- Article header image upload
app:match("article_upload", "/admin/articles/upload", respond_to({
  before = function(self)
    if self.session.role ~= "admin" and self.session.role ~= "editor" then
      return { redirect_to = "/" }
    end
  end,
  POST = function(self)
    return handle_upload(self, "/admin/articles", "article_id", require("models.articles"))
  end
}))

-- Event header image upload
app:match("event_upload", "/admin/events/upload", respond_to({
  before = function(self)
    if self.session.role ~= "admin" and self.session.role ~= "editor" then
      return { redirect_to = "/" }
    end
  end,
  POST = function(self)
    return handle_upload(self, "/admin/events", "event_id", require("models.events"))
  end
}))

-- Logout — expires the session cookie and redirects home
app:match("logout", "/logout", respond_to({
  GET = function(self)
    ngx.header["Set-Cookie"] = "lapis_session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
    return { redirect_to = self:url_for("index") }
  end
}))

return app
