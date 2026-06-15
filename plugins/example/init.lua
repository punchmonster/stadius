-- plugins/example/init.lua — demo plugin
local hooks = require("modules.hooks")

-- Add a link to the homepage sidebar
hooks.on("homepage_sidebar", function()
  return '<p style="font-size: 0.8rem; margin: 0.5rem 0;"><em>Plugin example active</em></p>'
end)

-- Add extra info in the footer
hooks.on("footer_links", function()
  return '<span class="text-muted" style="font-size: 0.7rem;"> &middot; extended by plugins</span>'
end)
