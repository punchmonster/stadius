--[[
  controllers/error.lua — Error page controller
  Displays error messages passed via query parameters or route segments.
  Used by other controllers when they need to show an error to the user.
--]]

return {

  --[[
    before: Sets metadata for the error page layout.
  --]]
  before = function(self)
    self.page_title = "error"
    self.header_vis = false
  end,

  --[[
    GET: Renders the error page.
    Reads an optional error code from the URL or query string.
  --]]
  GET = function(self)
    -- Get error code from route parameter (e.g., /error/not_found)
    -- or from query string (e.g., /error?errorCode=not_found)
    self.error_code = self.params.errorCode or "unknown_error"

    return { render = "error" }
  end,

}
