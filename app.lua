--[[
  app.lua — Stadius application entry point
  Defines routes and loads controllers.
--]]

local lapis = require("lapis")
local respond_to = require("lapis.application").respond_to

local app = lapis.Application()

-- Enable etlua templating
app:enable("etlua")
app.layout = require("views.layout")

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
local admin_settings_controller = require("controllers.admin_settings")
local admin_pages_controller   = require("controllers.admin_pages")
local profile_controller      = require("controllers.profile")
local page_controller          = require("controllers.page")
local contact_controller       = require("controllers.contact")
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

-- Admin site settings
app:match("admin_settings", "/admin/settings", respond_to(admin_settings_controller))

-- Admin page builder
app:match("admin_pages", "/admin/pages", respond_to(admin_pages_controller))

-- Public agenda page (listing)
app:match("agenda", "/agenda", respond_to(events_controller))

-- Single event page
app:match("event", "/agenda/:id", respond_to(events_controller))

-- Custom pages (public)
app:match("page", "/page/:slug", respond_to(page_controller))

-- Contact page
app:match("contact", "/contact", respond_to(contact_controller))

-- Logout — expires the session cookie and redirects home
app:match("logout", "/logout", respond_to({
  GET = function(self)
    ngx.header["Set-Cookie"] = "lapis_session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
    return { redirect_to = self:url_for("index") }
  end
}))

return app
