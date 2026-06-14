--[[ modules/helpers.lua — tiny shared utilities used across controllers ]]

-- Parse a comma-separated string into a trimmed array of tags.
local function parse_tags(str)
  local tags = {}
  if str then
    for tag in str:gmatch("[^,]+") do
      local t = tag:match("^%s*(.-)%s*$")
      if #t > 0 then table.insert(tags, t) end
    end
  end
  return tags
end

-- Treat empty string as nil, otherwise return the value as-is.
local function nil_if_empty(s)
  if s == nil or s == "" then return nil end
  return s
end

return { parse_tags = parse_tags, nil_if_empty = nil_if_empty }
