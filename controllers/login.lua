--[[
  controllers/login.lua — Login page controller
  Handles GET (render form) and POST (process login or signup) for "/login".
  Delegates authentication to models.user. Redirects admins to /admin on login.
--]]

local User = require("models.user")

return {

  --[[
    Sets page metadata before every action on this controller.

    Self contains the request context (params, session, url_for, etc.).
    Mutates self.page_title and self.submit_url in place. No return value.
  --]]
  before = function(self)
    self.page_title = "login"
    self.submit_url = self:url_for("login")
  end,

  --[[
    Renders the login/signup form, or redirects already-logged-in users
    to their role-appropriate landing page.

    Self contains the request context with self.session.

    Returns { render = "login" } or { redirect_to = "/admin" | "/profile" }.
  --]]
  GET = function(self)
    if self.session.username then
      if self.session.role == "admin" then
        return { redirect_to = self:url_for("admin") }
      else
        return { redirect_to = self:url_for("profile") }
      end
    end
    return { render = "login" }
  end,

  --[[
    Processes a login or signup form submission.
    Signup only requires username and password.

    Self contains the request context with self.params.username,
    self.params.password, and self.params.action.

    On successful login: records last_login and last_ip, sets session, redirects
    admins to /admin and everyone else to /profile.
    On successful signup: sets session, redirects to /profile.
    On failure: sets self.error_message, returns { render = "login" }.
  --]]
  POST = function(self)
    local action = self.params.action
    local username = self.params.username
    local password = self.params.password

    if action == "signup" then
      local ok, msg = User.create(username, password)
      if ok then
        local user = User.find_by_username(username)
        self.session.username = username
        self.session.role = user and user.role or User.DEFAULT_ROLE
        return { redirect_to = self:url_for("profile") }
      else
        self.error_message = msg
        return { render = "login" }
      end
    else
      local ok, user_or_msg = User.login(username, password)
      if ok then
        self.session.username = username
        self.session.role = user_or_msg.role

        -- Record login timestamp and IP
        local ip = ngx and ngx.var.remote_addr or "127.0.0.1"
        User.record_login(username, ip)

        -- Admins land on the admin dashboard, everyone else goes to profile
        if user_or_msg.role == "admin" then
          return { redirect_to = self:url_for("admin") }
        else
          return { redirect_to = self:url_for("profile") }
        end
      else
        self.error_message = user_or_msg
        return { render = "login" }
      end
    end
  end,

}
