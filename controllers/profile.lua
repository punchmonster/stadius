--[[
  controllers/profile.lua — User profile controller
  Handles GET (show profile) and POST (update email / phone / password)
  for the "/profile" route. Requires a logged-in session.
--]]

local User = require("models.user")

return {

  --[[
    Guards against unauthenticated access and loads user data.

    Self contains the request context.
    Redirects to /login if no session exists.
    Sets self.page_title, self.current_user, and self.user_data.
  --]]
  before = function(self)
    self.page_title = "profile"

    if not self.session.username then
      return { redirect_to = self:url_for("login") }
    end

    self.current_user = self.session.username
    self.user_data = User.find_by_username(self.session.username)
  end,

  --[[
    Renders the profile page showing the user's role, email, phone, and
    a form to update those fields plus password.

    Returns { render = "profile" }.
  --]]
  GET = function(self)
    return { render = "profile" }
  end,

  --[[
    Processes profile updates. The user can edit their email, phone, and
    password. Role cannot be changed by the user themselves.

    Self.params contains: new_email, new_phone, new_password.

    On success or failure: sets self.message, re-loads user_data, re-renders.
    Returns { render = "profile" }.
  --]]
  POST = function(self)
    -- Helper: empty string means "no change"
    local function nil_if_empty(s)
      if s == nil or s == "" then return nil end
      return s
    end

    local new_email    = nil_if_empty(self.params.new_email)
    local new_phone    = nil_if_empty(self.params.new_phone)
    local new_password = nil_if_empty(self.params.new_password)

    local ok, msg = User.update_user(self.session.username, nil, new_password,
                                      new_email, new_phone)
    if ok then
      self.message = "Profile updated."
    else
      self.message = msg
    end

    -- Reload fresh user data
    self.user_data = User.find_by_username(self.session.username)

    return { render = "profile" }
  end,

}
