--[[
  controllers/login.lua — Login page controller
  Handles GET and POST for the "/login" route.
  GET renders the login form, POST processes authentication.
  Currently uses a simple placeholder auth — extend with real user model later.
--]]

return {

  --[[
    before: Runs before every action on this controller.
    Hides the header for a cleaner login page, sets page title.
  --]]
  before = function(self)
    -- Hide the global header on the login page for a focused UX
    self.header_vis = false

    -- Page title shown in browser tab
    self.page_title = "login"

    -- Build the form submission URL
    self.submit_url = self:url_for("login")
  end,

  --[[
    GET: Renders the login form.
  --]]
  GET = function(self)
    return { render = "login" }
  end,

  --[[
    POST: Processes the login form submission.
    Validates credentials and sets a session on success.
    Redirects to home on success, or renders login with an error message.
  --]]
  POST = function(self)
    -- Retrieve form fields from the request parameters
    local username = self.params.username
    local password = self.params.password

    -- Validate that both fields are present
    if not username or #username < 3 then
      self.error_message = "Username must be at least 3 characters."
      return { render = "login" }
    end

    if not password or #password < 3 then
      self.error_message = "Password must be at least 3 characters."
      return { render = "login" }
    end

    -- Placeholder authentication — replace with real user model lookup
    -- In production: local status, msg, userID = User:login(username, password)
    if username == "admin" and password == "admin" then
      -- Store user info in the session on successful login
      self.session.username = username
      return { redirect_to = self:url_for("index") }
    else
      -- Show error and re-render the login form
      self.error_message = "Invalid username or password."
      return { render = "login" }
    end
  end,

}
