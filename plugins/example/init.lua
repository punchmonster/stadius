-- plugins/example/init.lua — demo plugin
local hooks = require("modules.hooks")

hooks.on("homepage_sidebar", function()
  return '<p style="font-size: 0.8rem; margin: 0.5rem 0;"><em>Plugin example active</em></p>'
end)

hooks.on("footer_links", function()
  return '<span class="text-muted" style="font-size: 0.7rem;"> &middot; extended by plugins</span>'
end)

-- Shortcode: type {{ greeting }} or {{ greeting: Name }} in any editor
hooks.shortcode("greeting", function(name)
  local who = name or "friend"
  return "**Hello, " .. who .. "!** This was inserted by a plugin shortcode."
end)
