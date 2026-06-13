--[[
  app.lua — Main application entry point for Stadius
  Sets up Lapis with etlua templating, loads controllers, and defines routes.
  Follows the MVC pattern from anzu-git reference project.
--]]

local lapis = require("lapis")
local config = require("lapis.config")
local respond_to = require("lapis.application").respond_to

-- Create the Lapis application
local app = lapis.Application()

-- Enable etlua templating (embedded Lua in HTML templates)
app:enable("etlua")

-- Set the global layout template that wraps all pages
app.layout = require("views.layout")

-- ---------------------------------------------------------------------------
-- Load Controllers
-- ---------------------------------------------------------------------------
-- Each controller handles a specific set of routes and returns a table
-- with 'before', 'GET', and optionally 'POST' functions.
local index_controller    = require("controllers.index")
local articles_controller = require("controllers.articles")
local login_controller    = require("controllers.login")
local error_controller    = require("controllers.error")

-- ---------------------------------------------------------------------------
-- Define Routes
-- ---------------------------------------------------------------------------
-- Using respond_to to map URL patterns to controller actions.
-- The controller name becomes the route name (used with url_for).

-- Home page — shown when user visits "/"
app:match("/",               respond_to(index_controller))

-- Articles page — lists/display articles
app:match("/articles",       respond_to(articles_controller))

-- Login page — user authentication
app:match("/login",          respond_to(login_controller))

-- Error page — displays error messages passed via query params
app:match("/error",          respond_to(error_controller))

-- ---------------------------------------------------------------------------
-- Error handling — catch-all for undefined routes (404)
-- ---------------------------------------------------------------------------
app:match("/error/:errorCode", respond_to({
  GET = function(self)
    return { render = "error", status = 404 }
  end
}))

-- Return the application to Lapis
return app
