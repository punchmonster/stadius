--[[
  modules/image.lua — Image validation, resizing, and conversion
  Uses ImageMagick `convert` to process uploads.
  - Only allows jpg, png, webp input
  - Resizes to max 3000x3000 (only if larger)
  - Always converts output to jpg
  - Compresses with quality 85
]]

local UPLOAD_DIR = "static/uploads/media/"
local MAX_DIM = 3000
local QUALITY = 85

--[[
  Validates the file extension. Returns true for jpg/jpeg/png/webp.

  Args:
    filename — string, original filename

  Returns:
    boolean
--]]
local function is_allowed(filename)
  if not filename then return false end
  local ext = filename:lower():match("%.([^%.]+)$")
  return ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp"
end

--[[
  Processes an uploaded image: validates type, resizes if larger than
  3000x3000, converts to jpg with quality 85, and saves.

  Args:
    content  — string, raw file bytes
    filename — string, original filename

  Returns:
    out_name, file_size, nil   on success
    nil, nil, error_message    on failure
--]]
local function process(content, filename)
  if not is_allowed(filename) then
    return nil, nil, "Only JPG, PNG, and WebP images are allowed"
  end

  -- Build output name (always .jpg)
  local base = filename:gsub("%.[^%.]+$", "")
  base = base:gsub("[^%w%.%-]", "_")
  local out_name = os.time() .. "_" .. base .. ".jpg"

  local tmp_in = UPLOAD_DIR .. "_tmp_in_" .. out_name
  local tmp_out = UPLOAD_DIR .. "_tmp_out_" .. out_name

  -- Write temp input
  local f = io.open(tmp_in, "w")
  if not f then return nil, nil, "Cannot write temp file" end
  f:write(content)
  f:close()

  -- ImageMagick: resize (only shrink, never enlarge), auto-orient, convert to jpg
  local cmd = "convert " .. tmp_in
    .. " -resize '" .. MAX_DIM .. "x" .. MAX_DIM .. ">'"
    .. " -quality " .. QUALITY
    .. " -auto-orient"
    .. " '" .. tmp_out .. "'"
  local ok = os.execute(cmd)

  -- Clean up input temp
  os.remove(tmp_in)

  if not ok then
    os.remove(tmp_out)
    return nil, nil, "Image processing failed — file may be corrupted"
  end

  -- Move to final path
  local final_path = UPLOAD_DIR .. out_name
  local moved = os.rename(tmp_out, final_path)
  if not moved then
    os.remove(tmp_out)
    return nil, nil, "Cannot save processed image"
  end

  -- Get file size
  local size = 0
  local sf = io.open(final_path, "r")
  if sf then
    size = sf:seek("end")
    sf:close()
  end

  return out_name, size, nil
end

--[[
  Saves an uploaded file, creates a media record, and returns the filename.
  Convenience wrapper used by controllers.

  Args:
    params — the self.params table from a Lapis request

  Returns:
    filename (string) on success, or nil on failure / no file
--]]
local function save_upload(params, username)
  local file = params.header_image
  if not file or not file.content or #file.content == 0 then return nil end
  local name, size, err = process(file.content, file.filename)
  if not name then return nil end
  local Media = require("models.media")
  local tags = {}
  if params.image_tags then
    for tag in params.image_tags:gmatch("[^,]+") do
      local t = tag:match("^%s*(.-)%s*$")
      if #t > 0 then table.insert(tags, t) end
    end
  end
  Media.create(name, params.image_title, params.image_alt,
               params.image_credit, tags, username or "", size)
  return name
end

return { process = process, is_allowed = is_allowed, save_upload = save_upload }
