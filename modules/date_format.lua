--[[ modules/date_format.lua — human-readable dates with GMT offset ]]

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

-- Rough GMT offsets for common timezones (standard time, no DST).
-- For production, use a proper tz database. These cover common zones.
local OFFSETS = {
  UTC = 0, ["Europe/London"] = 0, ["Europe/Amsterdam"] = 1, ["Europe/Berlin"] = 1,
  ["Europe/Paris"] = 1, ["America/New_York"] = -5, ["America/Chicago"] = -6,
  ["America/Denver"] = -7, ["America/Los_Angeles"] = -8, ["Asia/Tokyo"] = 9,
  ["Asia/Shanghai"] = 8, ["Australia/Sydney"] = 10,
}

local cached_zone = nil

local function get_zone()
  if not cached_zone then
    local Settings = require("models.settings")
    cached_zone = Settings.get().timezone or "UTC"
  end
  return cached_zone
end

local function fmt_offset(offset)
  if offset == 0 then return "GMT" end
  local sign = offset > 0 and "+" or "-"
  local h = math.abs(offset)
  return "GMT" .. sign .. string.format("%02d:00", h)
end

local function format(iso)
  if not iso or iso == "" then return "-" end
  local y, m, d, h, min = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
  if y then
    local month = MONTHS[tonumber(m)]
    local zone = get_zone()
    local offset = OFFSETS[zone] or 0
    local label = fmt_offset(offset)
    return month .. " " .. tonumber(d) .. ", " .. y .. " " .. h .. ":" .. min .. " " .. label
  end
  y, m, d = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if y then
    local month = MONTHS[tonumber(m)]
    return month .. " " .. tonumber(d) .. ", " .. y
  end
  return iso
end

local function refresh()
  cached_zone = nil
end

return { format = format, refresh = refresh }
