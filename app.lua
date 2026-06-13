--[[
  app.lua — Stadius application entry point
  Defines routes and loads controllers.
--]]

local lapis = require("lapis")
local respond_to = require("lapis.application").respond_to

local app = lapis.Application()

-- Enable etlua templating
app:enable("etlua")

-- ---------------------------------------------------------------------------
-- Load Controllers
-- ---------------------------------------------------------------------------
local index_controller        = require("controllers.index")
local login_controller        = require("controllers.login")
local admin_controller        = require("controllers.admin")
local admin_users_controller  = require("controllers.admin_users")
local admin_articles_controller = require("controllers.admin_articles")
local admin_events_controller   = require("controllers.admin_events")
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

-- Public agenda page (listing)
app:match("agenda", "/agenda", respond_to(events_controller))

-- Single event page
app:match("event", "/agenda/:id", respond_to(events_controller))

return app
