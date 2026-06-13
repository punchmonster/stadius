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

-- ---------------------------------------------------------------------------
-- Routes
-- ---------------------------------------------------------------------------

-- Home page
app:match("index", "/", respond_to(index_controller))

-- Login page — GET renders form, POST processes login/signup
app:match("login", "/login", respond_to(login_controller))

return app
