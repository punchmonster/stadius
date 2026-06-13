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
local index_controller = require("controllers.index")
local login_controller = require("controllers.login")
local admin_controller = require("controllers.admin")

-- ---------------------------------------------------------------------------
-- Routes
-- ---------------------------------------------------------------------------

-- Home page
app:match("index", "/", respond_to(index_controller))

-- Login page — GET renders form, POST processes login/signup
app:match("login", "/login", respond_to(login_controller))

-- Admin dashboard — protected by role check in the controller's before filter
app:match("admin", "/admin", respond_to(admin_controller))

return app
