--[[ modules/hooks.lua — hook registry + shortcode system for plugins ]]
local registry = {}
local shortcodes = {}

-- Register a callback for a named hook point (positional hooks).
local function on(name, fn)
  if not registry[name] then registry[name] = {} end
  table.insert(registry[name], fn)
end

-- Returns all registered callbacks for a hook point (or empty table).
local function get(name)
  return registry[name] or {}
end

-- Register a shortcode that can be embedded in page/article content.
-- Usage in editor: {{ my-token }}  or  {{ my-token: some argument }}
local function shortcode(token, fn)
  shortcodes[token] = fn
end

-- Process shortcodes in a string. Returns the string with shortcodes replaced.
-- Tokens are matched as {{ token }} or {{ token: arg }}
local function render_shortcodes(text)
  if not text then return text end
  text = text:gsub("%{%{%s*([%w%-]+)%s*:%s*([^}]*)%}%}", function(token, arg)
    local fn = shortcodes[token]
    if fn then return fn(arg:match("^%s*(.-)%s*$")) or "" end
    return "{{ " .. token .. ": " .. arg .. " }}"
  end)
  text = text:gsub("%{%{%s*([%w%-]+)%s*%}%}", function(token)
    local fn = shortcodes[token]
    if fn then return fn(nil) or "" end
    return "{{ " .. token .. " }}"
  end)
  return text
end

return { on = on, get = get, shortcode = shortcode, render_shortcodes = render_shortcodes }
