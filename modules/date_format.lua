--[[
  modules/date_format.lua — Human-readable date formatting
  Converts ISO date strings to readable forms like "Jun 13, 2026 10:28 UTC".
]]

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

--[[
  Formats an ISO date string. Returns "-" for nil/empty input.

  "2026-06-13T10:28:52Z" -> "Jun 13, 2026 10:28 UTC"
  "2026-06-13"            -> "Jun 13, 2026"
  nil / ""                 -> "-"

  Args:
    iso — string or nil, ISO-8601 date

  Returns:
    string, human-readable date
--]]
local function format(iso)
  if not iso or iso == "" then return "-" end
  local y, m, d, h, min = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
  if y then
    local month = MONTHS[tonumber(m)]
    return month .. " " .. tonumber(d) .. ", " .. y .. " " .. h .. ":" .. min .. " UTC"
  end
  y, m, d = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if y then
    local month = MONTHS[tonumber(m)]
    return month .. " " .. tonumber(d) .. ", " .. y
  end
  return iso -- fallback: return as-is
end

return { format = format }
