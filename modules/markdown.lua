--[[
  modules/markdown.lua — Basic Markdown-to-HTML converter
  Converts a subset of Markdown syntax to HTML. Not CommonMark-compliant but
  covers the essentials: headings, bold, italic, code, links, images, lists,
  blockquotes, code blocks, and horizontal rules.

  Exported function:
    to_html(md_string) -> html_string
--]]

-- ---------------------------------------------------------------------------
-- Inline parsing
-- ---------------------------------------------------------------------------

--[[
  Escapes HTML entities in plain text so user input is safe for rendering.

  Args:
    text — string, raw text

  Returns:
    string, HTML-escaped text
--]]
local function escape_html(text)
  return (text:gsub("&", "&amp;")
              :gsub("<", "&lt;")
              :gsub(">", "&gt;"))
end

--[[
  Processes inline markdown within a single line of text.
  Handles: **bold**, *italic*, `code`, ![image](url), [link](url).

  Args:
    text — string, a single line of markdown text

  Returns:
    string, the line with inline markdown converted to HTML
--]]
local function parse_inline(text)
  -- Escape HTML first to prevent injection
  text = escape_html(text)

  -- Images must be handled before links (they share ]( pattern)
  text = text:gsub("!%[([^%]]*)%]%(([^%)]*)%)", '<img src="%2" alt="%1">')

  -- Links [text](url)
  text = text:gsub("%[([^%]]*)%]%(([^%)]*)%)", '<a href="%2">%1</a>')

  -- Bold **text**
  text = text:gsub("%*%*([^%*]-)%*%*", "<strong>%1</strong>")

  -- Italic *text* (single asterisk, not part of **)
  text = text:gsub("%*([^%*]-)%*", "<em>%1</em>")

  -- Inline code `text`
  text = text:gsub("`([^`]-)`", "<code>%1</code>")

  return text
end

-- ---------------------------------------------------------------------------
-- Block-level parsing
-- ---------------------------------------------------------------------------

--[[
  Helper: returns true if the line looks like a block-level token start.
  Used by the paragraph collector to know when to stop.
--]]
local function is_block_start(line)
  return line:match("^%s*$")
      or line:match("^#")
      or line:match("^```")
      or line:match("^%-%-%-+%s*$")
      or line:match("^%*%*%*+%s*$")
      or line:match("^>")
      or line:match("^[%-%*]%s+")
      or line:match("^%d+%.%s+")
end

--[[
  Converts a markdown string to HTML.

  Args:
    md — string, the raw markdown content

  Returns:
    string, the converted HTML
--]]
local function to_html(md)
  if not md or md == "" then
    return ""
  end

  -- Process shortcodes before markdown conversion
  local hooks = require("modules.hooks")
  md = hooks.render_shortcodes(md)

  local lines = {}
  for line in md:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  local html = {}
  local i = 1
  local safety = 0  -- prevent infinite loops

  while i <= #lines and safety < 10000 do
    safety = safety + 1
    local line = lines[i]

    -- Blank line
    if line:match("^%s*$") then
      i = i + 1

    -- Fenced code block
    elseif line:match("^```") then
      local code_lines = {}
      i = i + 1
      while i <= #lines and not lines[i]:match("^```") and safety < 10000 do
        table.insert(code_lines, escape_html(lines[i]))
        i = i + 1
        safety = safety + 1
      end
      i = i + 1 -- skip closing ```
      table.insert(html, "<pre><code>" .. table.concat(code_lines, "\n") .. "</code></pre>")

    -- Horizontal rule
    elseif line:match("^%-%-%-+%s*$") or line:match("^%*%*%*+%s*$") then
      table.insert(html, "<hr>")
      i = i + 1

    -- Headings (one or more #)
    elseif line:match("^#+%s") then
      local content = line:gsub("^#+%s*", "")
      local level = #line:match("^#+")
      level = math.min(level, 6)
      table.insert(html, "<h" .. level .. ">" .. parse_inline(content) .. "</h" .. level .. ">")
      i = i + 1

    -- Blockquote
    elseif line:match("^>%s?") then
      local quote_lines = {}
      while i <= #lines and lines[i]:match("^>%s?") and safety < 10000 do
        table.insert(quote_lines, lines[i]:gsub("^>%s?", ""))
        i = i + 1
        safety = safety + 1
      end
      table.insert(html, "<blockquote>" .. to_html(table.concat(quote_lines, "\n")) .. "</blockquote>")

    -- Unordered list
    elseif line:match("^[%-%*]%s+") then
      table.insert(html, "<ul>")
      while i <= #lines and lines[i]:match("^[%-%*]%s+") and safety < 10000 do
        local item = lines[i]:gsub("^[%-%*]%s+", "")
        table.insert(html, "<li>" .. parse_inline(item) .. "</li>")
        i = i + 1
        safety = safety + 1
      end
      table.insert(html, "</ul>")

    -- Ordered list
    elseif line:match("^%d+%.%s+") then
      table.insert(html, "<ol>")
      while i <= #lines and lines[i]:match("^%d+%.%s+") and safety < 10000 do
        local item = lines[i]:gsub("^%d+%.%s+", "")
        table.insert(html, "<li>" .. parse_inline(item) .. "</li>")
        i = i + 1
        safety = safety + 1
      end
      table.insert(html, "</ol>")

    -- Paragraph
    else
      local para_lines = {}
      while i <= #lines and not is_block_start(lines[i]) and safety < 10000 do
        table.insert(para_lines, parse_inline(lines[i]))
        i = i + 1
        safety = safety + 1
      end
      local paragraph = table.concat(para_lines, " ")
      if paragraph ~= "" then
        table.insert(html, "<p>" .. paragraph .. "</p>")
      end
    end
  end

  return table.concat(html, "\n")
end

return {
  to_html = to_html,
}
