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
    Renders the login/signup form.

    Self contains the request context.
    Returns { render = "login" } to render views/login.etlua.
  --]]
  GET = function(self)
    return { render = "login" }
  end,

  --[[
    Processes a login or signup form submission.
    Reads self.params.action to decide which flow to run ("login" or "signup").

    Self contains the request context with self.params.username, self.params.password,
    and self.params.action.

    On successful login: sets self.session.username and self.session.role,
    then redirects admins to /admin and everyone else to /.
    On successful signup: sets self.session.username and self.session.role,
    then redirects to /.
    On failure: sets self.error_message, returns { render = "login" }.
  --]]
  POST = function(self)
    local action = self.params.action
    local username = self.params.username
    local password = self.params.password

    if action == "signup" then
      local ok, msg = User.create(username, password)
      if ok then
        -- New signups always get the default role, look it up
        local user = User.find_by_username(username)
        self.session.username = username
        self.session.role = user and user.role or User.DEFAULT_ROLE
        return { redirect_to = self:url_for("index") }
      else
        self.error_message = msg
        return { render = "login" }
      end
    else
      -- Login: User.login now returns (true, user_table) on success
      local ok, user_or_msg = User.login(username, password)
      if ok then
        self.session.username = username
        self.session.role = user_or_msg.role

        -- Admins land on the admin dashboard, everyone else goes home
        if user_or_msg.role == "admin" then
          return { redirect_to = self:url_for("admin") }
        else
          return { redirect_to = self:url_for("index") }
        end
      else
        self.error_message = user_or_msg
        return { render = "login" }
      end
    end
  end,

}
