--[[ modules/hooks.lua — simple hook registry for plugins ]]
local registry = {}

-- Register a callback for a named hook point.
-- Multiple plugins can register for the same hook; all are called in order.
local function on(name, fn)
  if not registry[name] then registry[name] = {} end
  table.insert(registry[name], fn)
end

-- Returns all registered callbacks for a hook point (or empty table).
local function get(name)
  return registry[name] or {}
end

return { on = on, get = get }
