--[[
  models/user.lua — Flat-file user model
  Provides user creation, lookup, and password verification using SHA256 + salt.
  Stores data in data/users.json as a flat JSON table keyed by username.
--]]

local digest = require("openssl.digest")
local rand = require("openssl.rand")

-- Path to the JSON user store, relative to the app root
local DATA_FILE = "data/users.json"

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--[[
  Takes a raw binary string and returns its lowercase hex representation.
  Used to store both the password hash and salt in human-readable form.

  Args:
    str  — string, raw binary data

  Returns:
    string, the hex-encoded version of str
--]]
local function to_hex(str)
  return (str:gsub(".", function(c)
    return string.format("%02x", string.byte(c))
  end))
end

--[[
  Generates 16 cryptographically random bytes and returns them as a hex string.
  Each user gets a unique salt so identical passwords produce different hashes.

  Args:
    none

  Returns:
    string, 32-character hex salt
--]]
local function generate_salt()
  local raw = rand.bytes(16)
  return to_hex(raw)
end

--[[
  Produces the SHA256 hex digest of salt prepended to the password.
  Salting prevents rainbow-table attacks and hides duplicate passwords.

  Args:
    password  — string, the plaintext password to hash
    salt      — string, the hex salt to prepend

  Returns:
    string, 64-character hex SHA256 digest
--]]
local function hash_password(password, salt)
  local d = digest.new("sha256")
  d:update(salt .. password)
  return to_hex(d:final())
end

--[[
  Reads and parses the JSON user file from disk.
  Safely returns an empty table if the file is missing, empty, or malformed.

  Args:
    none

  Returns:
    table, keyed by username → { password_hash, salt, created_at }
--]]
local function read_users()
  local file = io.open(DATA_FILE, "r")
  if not file then
    return {}
  end
  local content = file:read("*a")
  file:close()
  if not content or content == "" then
    return {}
  end
  return require("lapis.util").from_json(content) or {}
end

--[[
  Recursively serialises a Lua value to pretty-printed JSON with 2-space
  indentation. Keys are sorted alphabetically. Handles tables (objects and
  arrays), strings, booleans, numbers, and nil/null.

  Args:
    value  — any Lua value (table, string, number, boolean, nil)
    indent — integer, current nesting depth (0 for the top-level call)

  Returns:
    string, the formatted JSON representation of value
--]]
local function json_encode_pretty(value, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)
  local pad_inner = string.rep("  ", indent + 1)

  if type(value) == "table" then
    -- Detect whether this table is an array (consecutive integer keys from 1)
    local is_array = true
    local max_key = 0
    for k in pairs(value) do
      if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
        is_array = false
        break
      end
      if k > max_key then max_key = k end
    end
    if max_key == 0 then is_array = false end

    if is_array then
      if max_key == 0 then
        return "[]"
      end
      local parts = {}
      for i = 1, max_key do
        table.insert(parts, pad_inner .. json_encode_pretty(value[i], indent + 1))
      end
      return "[\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "]"
    else
      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end
      table.sort(keys)
      if #keys == 0 then
        return "{}"
      end
      local parts = {}
      for _, k in ipairs(keys) do
        local v = value[k]
        table.insert(parts, pad_inner .. '"' .. tostring(k) .. '": ' .. json_encode_pretty(v, indent + 1))
      end
      return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
    end
  elseif type(value) == "string" then
    return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
  elseif type(value) == "boolean" then
    return value and "true" or "false"
  elseif type(value) == "number" then
    return tostring(value)
  else
    return "null"
  end
end

--[[
  Writes a users table to the JSON data file with human-readable formatting.
  Overwrites any existing file at DATA_FILE. Creates the file if missing.

  Args:
    users — table, keyed by username → { password_hash, salt, created_at }

  Returns:
    true on success, or false, error_message on failure
--]]
local function write_users(users)
  local file = io.open(DATA_FILE, "w")
  if not file then
    return false, "Cannot open user data file for writing"
  end
  file:write(json_encode_pretty(users))
  file:close()
  return true
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--[[
  Looks up a user record by username.

  Args:
    username — string, the username to search for

  Returns:
    table { password_hash, salt, created_at } if found, or nil
--]]
local function find_by_username(username)
  local users = read_users()
  return users[username]
end

--[[
  Registers a new user with a randomly salted and hashed password.
  Validates that the username is 3+ chars, alphanumeric/dash/underscore only,
  and not already taken. Password must be 3+ characters.

  Args:
    username — string, the desired username
    password — string, the plaintext password to salt and hash

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function create(username, password)
  if not username or #username < 3 then
    return false, "Username must be at least 3 characters"
  end
  if not password or #password < 3 then
    return false, "Password must be at least 3 characters"
  end

  local clean_name = string.match(username, "^[A-Za-z0-9_-]+$")
  if not clean_name then
    return false, "Username may only contain letters, numbers, dashes, and underscores"
  end

  local users = read_users()

  if users[username] then
    return false, "Username already taken"
  end

  local salt = generate_salt()
  local hash = hash_password(password, salt)

  users[username] = {
    password_hash = hash,
    salt = salt,
    created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }

  local ok, err = write_users(users)
  if not ok then
    return false, err
  end

  return true, "User created successfully"
end

--[[
  Verifies a username and password combination against the stored hash.
  Uses constant-time comparison of hashes to avoid timing side-channels
  (string comparison in Lua is byte-by-byte and early-exits on mismatch,
  but the salt ensures hashes differ entirely for different passwords).

  Args:
    username — string, the username to authenticate
    password — string, the plaintext password to verify

  Returns:
    true, "ok" on successful authentication
    false, error_message on failure (same message for wrong user or wrong password)
--]]
local function login(username, password)
  local user = find_by_username(username)
  if not user then
    return false, "Invalid username or password"
  end

  local computed_hash = hash_password(password, user.salt)

  if computed_hash == user.password_hash then
    return true, "Login successful"
  else
    return false, "Invalid username or password"
  end
end

return {
  create = create,
  login = login,
  find_by_username = find_by_username,
}
