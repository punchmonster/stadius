--[[
  controllers/events.lua — Public agenda controller
  Handles GET "/agenda" (list) and GET "/agenda/:id" (single event with RSVP).
--]]

local Events = require("models.events")
local Markdown = require("modules.markdown")
local DF = require("modules.date_format")

return {

  before = function(self)
    self.page_title = "agenda"
    self.section = "agenda"
  end,

  --[[
    Lists upcoming events or shows a single event page.
    Single event: RSVP toggle available if logged in and RSVP is enabled.

    Query params for single: self.params.id
    Query params for RSVP: self.params.rsvp ("1" to toggle)
  --]]
  GET = function(self)
    local id = tonumber(self.params.id)

    if id then
      -- Single event view
      local event = Events.find_by_id(id)
      if not event then
        return { render = "event", status = 404 }
      end

      event._created = DF.format(event.created_at)
      event._event_date = DF.format(event.event_date)
      event.description_html = Markdown.to_html(event.description)
      self.event = event
      self.page_title = event.title

      -- Check if current user has RSVP'd
      local username = self.session.username
      self.is_logged_in = username ~= nil
      self.has_rsvpd = false
      if username and event.rsvps then
        for _, u in ipairs(event.rsvps) do
          if u == username then self.has_rsvpd = true break end
        end
      end

      return { render = "event" }
    else
      -- Agenda listing
      local events = Events.list_upcoming()
      for _, e in ipairs(events) do
        e._created = DF.format(e.created_at)
        e._event_date = DF.format(e.event_date)
        e.description_html = Markdown.to_html(e.description)
      end
      self.events = events
      return { render = "events" }
    end
  end,

  --[[
    Handles RSVP toggle on a single event.
  --]]
  POST = function(self)
    local id = tonumber(self.params.id)
    local username = self.session.username

    if not username then
      return { redirect_to = self:url_for("login") }
    end

    if not id then
      return { redirect_to = self:url_for("agenda") }
    end

    local ok, action = Events.toggle_rsvp(id, username)
    if ok then
      if action == "rsvp" then
        self.message = "You have RSVP'd."
      else
        self.message = "RSVP cancelled."
      end
    else
      self.message = action  -- error message
    end

    -- Reload event
    local event = Events.find_by_id(id)
    if event then
      event.description_html = Markdown.to_html(event.description)
      self.event = event
      self.page_title = event.title
      self.is_logged_in = true
      self.has_rsvpd = false
      if event.rsvps then
        for _, u in ipairs(event.rsvps) do
          if u == username then self.has_rsvpd = true break end
        end
      end
    end

    return { render = "event" }
  end,

}
