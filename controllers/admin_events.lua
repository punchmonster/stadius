--[[
  controllers/admin_events.lua — Admin event editor
  Handles GET (list / create form / export RSVP) and POST (create / edit / delete)
  for "/admin/events". Only accessible to admins and editors.
  Mirrors the structure of admin_articles controller.
--]]

local Events = require("models.events")
local User = require("models.user")
local Permissions = require("models.permissions")
local DF = require("modules.date_format")

--[[
  Helper: slices event list for pagination and sets context fields on self.
--]]
local function paginate(self)
  local per_page = tonumber(self.params.per_page) or 10
  local valid_steps = { 5, 10, 20, 30, 40, 50 }
  local found = false
  for _, v in ipairs(valid_steps) do if v == per_page then found = true break end end
  if not found then per_page = 10 end

  local all = Events.list_all()
  local total = #all
  local total_pages = math.max(1, math.ceil(total / per_page))
  local page = tonumber(self.params.page) or 1
  if page < 1 then page = 1 end
  if page > total_pages then page = total_pages end
  local start = (page - 1) * per_page + 1
  local finish = math.min(start + per_page - 1, total)

  local paged = {}
  for i = start, finish do
    local e = all[i]
    e._created = DF.format(e.created_at)
    e._event_date = DF.format(e.event_date)
    table.insert(paged, e)
  end

  self.events = paged
  self.page = page
  self.total_pages = total_pages
  self.total_events = total
  self.per_page = per_page
  self.valid_steps = valid_steps
end

return {

  before = function(self)
    self.page_title = "admin - events"
    self.section = "events"
  end,

  --[[
    Shows event list or create/edit form. Requires "events" permission.
  --]]
  GET = function(self)
    if not Permissions.check(self.db_role, "events") then
      return { redirect_to = self:url_for("index") }
    end
    local action = self.params.action

    -- Export RSVPs as CSV
    if action == "export" and self.params.id then
      local event = Events.find_by_id(tonumber(self.params.id))
      if not event then
        return "Event not found", { status = 404 }
      end

      local fields = self.params.fields or "usernames"
      local rsvps = event.rsvps or {}
      local rows = {}

      -- Build header and rows based on selected fields
      local headers = {}
      if fields == "usernames" or fields == "all" then
        table.insert(headers, "Username")
      end
      if fields == "emails" or fields == "all" then
        table.insert(headers, "Email")
      end
      if fields == "phones" or fields == "all" then
        table.insert(headers, "Phone")
      end
      table.insert(rows, table.concat(headers, ","))

      for _, username in ipairs(rsvps) do
        local user = User.find_by_username(username)
        local cols = {}
        if fields == "usernames" or fields == "all" then
          local u = username:gsub('"', '""')
          table.insert(cols, '"' .. u .. '"')
        end
        if fields == "emails" or fields == "all" then
          local e = (user and user.email) or ""
          e = e:gsub('"', '""')
          table.insert(cols, '"' .. e .. '"')
        end
        if fields == "phones" or fields == "all" then
          local p = (user and user.phone) or ""
          p = p:gsub('"', '""')
          table.insert(cols, '"' .. p .. '"')
        end
        table.insert(rows, table.concat(cols, ","))
      end

      local csv = table.concat(rows, "\n")
      local filename = event.title:gsub("[^%w%-]", "_") .. "_rsvps.csv"

      -- Return raw CSV, bypassing the Lapis layout
      ngx.header["Content-Type"] = "text/csv; charset=utf-8"
      ngx.header["Content-Disposition"] = "attachment; filename=\"" .. filename .. "\""
      ngx.say(csv)
      return ngx.exit(ngx.HTTP_OK)
    end

    paginate(self)

    if action == "new" then
      self.mode = "new"
    elseif action == "edit" and self.params.id then
      self.mode = "edit"
      self.edit_event = Events.find_by_id(tonumber(self.params.id))
    else
      self.mode = "list"
    end

    return { render = "admin_events", layout = "admin_layout" }
  end,

  --[[
    Handles create, edit, delete. Re-renders list view with pagination.
  --]]
  POST = function(self)
    if not Permissions.check(self.db_role, "events") then
      return { redirect_to = self:url_for("index") }
    end

    local action = self.params.action

    if action == "create" then
      local ok, result = Events.create(
        self.params.title,
        self.params.description or "",
        self.params.event_date or "",
        self.session.username,
        self.params.location or "",
        self.params.rsvp_enabled or false
      )
      if ok then
        self.message = "Event created: #" .. tostring(result.id)
      else
        self.message = "Error: " .. result
      end

    elseif action == "edit" then
      local id = tonumber(self.params.id)
      if not id then
        self.message = "Invalid event id"
      else
        local updates = {}
        if self.params.title and #self.params.title > 0 then
          updates.title = self.params.title
        end
        updates.description = self.params.description or ""
        updates.event_date = self.params.event_date or ""
        updates.location = self.params.location or ""
        updates.rsvp_enabled = self.params.rsvp_enabled or false

        local ok, msg = Events.update(id, updates)
        self.message = msg
      end

    elseif action == "delete" then
      local id = tonumber(self.params.id)
      if not id then
        self.message = "Invalid event id"
      else
        local ok, msg = Events.delete(id)
        self.message = msg
      end
    end

    paginate(self)
    self.mode = "list"
    return { render = "admin_events", layout = "admin_layout" }
  end,

}
