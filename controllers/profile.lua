--[[
  controllers/profile.lua — User profile controller
  Handles GET (show profile) and POST (update email / phone / password)
  for the "/profile" route. Requires a logged-in session.
--]]

local User = require("models.user")
local H = require("modules.helpers")

return {

  --[[
    Guards against unauthenticated access and loads user data.

    Self contains the request context.
    Redirects to /login if no session exists.
    Sets self.page_title, self.current_user, and self.user_data.
  --]]
  before = function(self)
    self.page_title = "profile"
    self.section = "profile"
    if not self.session.username then
      return { redirect_to = self:url_for("login") }
    end

    self.current_user = self.session.username
    self.user_data = User.find_by_username(self.session.username)
  end,

  --[[
    Shows the profile page.

    Returns { render = "profile", layout = "admin_layout" }.
  --]]
  GET = function(self)
    return { render = "profile", layout = "admin_layout" }
  end,

  --[[
    Processes profile updates. Email, phone, and password are editable.

    Self.params: new_email, new_phone, new_password.

    On success or failure: sets self.message, re-loads user_data, re-renders.
    Returns { render = "profile", layout = "admin_layout" }.
  --]]
  POST = function(self)
    local new_email    = H.nil_if_empty(self.params.new_email)
    local new_phone    = H.nil_if_empty(self.params.new_phone)
    local new_password = H.nil_if_empty(self.params.new_password)

    local ok, msg = User.update_user(self.session.username, nil, new_password,
                                      new_email, new_phone)
    if ok then
      self.message = "Profile updated."
    else
      self.message = msg
    end

    self.user_data = User.find_by_username(self.session.username)

    return { render = "profile", layout = "admin_layout" }
  end,

}
