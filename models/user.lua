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
-- Roles — imported from the central permissions registry
-- ---------------------------------------------------------------------------

local Permissions = require("models.permissions")
local ROLES = Permissions.ROLES
local DEFAULT_ROLE = Permissions.DEFAULT_ROLE
local is_valid_role = Permissions.is_valid_role

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--[[
  Looks up a user record by username.
  Backfills a missing role field to the default for older records.

  Args:
    username — string, the username to search for

  Returns:
    table { password_hash, salt, role, created_at } if found, or nil
--]]
local function find_by_username(username)
  local users = read_users()
  local user = users[username]
  if user and not user.role then
    user.role = DEFAULT_ROLE
  end
  return user
end

--[[
  Registers a new user with a randomly salted and hashed password.
  Validates that the username is 3+ chars, alphanumeric/dash/underscore only,
  and not already taken. Password must be 3+ characters.
  The role parameter is only honoured by existing admin users — public signups
  always get the default role ("reader").

  Args:
    username — string, the desired username
    password — string, the plaintext password to salt and hash
    role     — string, optional role to assign (only used internally; ignored
               for public signups, defaults to "reader")
    email    — string or nil, the user's email address
    phone    — string or nil, the user's phone number

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function create(username, password, role, email, phone)
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

  -- Default to "reader" unless a valid role was explicitly passed
  local assigned_role = is_valid_role(role) and role or DEFAULT_ROLE

  local salt = generate_salt()
  local hash = hash_password(password, salt)
  local now = os.date("!%Y-%m-%dT%H:%M:%SZ")

  users[username] = {
    password_hash = hash,
    salt = salt,
    role = assigned_role,
    created_at = now,
    join_date = now,
    last_login = nil,
    last_password_change = now,
    last_ip = nil,
    email = email or "",
    phone = phone or "",
    subscription_active = false,
    subscription_start_date = nil,
    subscription_end_date = nil,
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
    true, user_table on successful authentication (user table contains role)
    false, error_message on failure
--]]
local function login(username, password)
  local user = find_by_username(username)
  if not user then
    return false, "Invalid username or password"
  end

  local computed_hash = hash_password(password, user.salt)

  if computed_hash == user.password_hash then
    return true, user
  else
    return false, "Invalid username or password"
  end
end

--[[
  Records a login timestamp and IP address for the given user.
  Called after successful authentication.

  Args:
    username — string, the user who just logged in
    ip       — string, the remote IP address (from ngx.var.remote_addr)

  Returns:
    true on success, false on failure
--]]
local function record_login(username, ip)
  local users = read_users()
  local user = users[username]

  if not user then
    return false
  end

  user.last_login = os.date("!%Y-%m-%dT%H:%M:%SZ")
  user.last_ip = ip or ""

  local ok = write_users(users)
  return ok
end

--[[
  Deletes a user by username.

  Args:
    username — string, the username to remove

  Returns:
    true, "ok" on success
    false, error_message if the user does not exist or the write fails
--]]
local function delete_user(username)
  local users = read_users()

  if not users[username] then
    return false, "User not found"
  end

  users[username] = nil

  local ok, err = write_users(users)
  if not ok then
    return false, err
  end

  return true, "User deleted"
end

--[[
  Updates a user's role, password, email, phone, and/or subscription fields.
  Pass nil for any field to leave it unchanged. When a new password is provided
  it is salted and hashed fresh and last_password_change is updated.

  Subscription fields:
    new_subscription_active — boolean or nil (true, false, or "true", "false")
    new_subscription_start  — string or nil, ISO-8601 date
    new_subscription_end    — string or nil, ISO-8601 date

  Args:
    username                — string, the user to update
    new_role                — string or nil
    new_password            — string or nil
    new_email               — string or nil
    new_phone               — string or nil
    new_subscription_active — boolean, "true", "false", or nil
    new_subscription_start  — string or nil
    new_subscription_end    — string or nil

  Returns:
    true, "ok" on success
    false, error_message on failure
--]]
local function update_user(username, new_role, new_password, new_email, new_phone,
                           new_subscription_active, new_subscription_start, new_subscription_end)
  local users = read_users()
  local user = users[username]

  if not user then
    return false, "User not found"
  end

  -- Update role if a valid one was passed
  if new_role then
    if not is_valid_role(new_role) then
      return false, "Invalid role: " .. tostring(new_role)
    end
    user.role = new_role
  end

  -- Update password if one was passed (re-hash with a fresh salt)
  if new_password and #new_password >= 3 then
    local salt = generate_salt()
    user.salt = salt
    user.password_hash = hash_password(new_password, salt)
    user.last_password_change = os.date("!%Y-%m-%dT%H:%M:%SZ")
  elseif new_password then
    return false, "Password must be at least 3 characters"
  end

  -- Update email if passed
  if new_email then
    user.email = new_email
  end

  -- Update phone if passed
  if new_phone then
    user.phone = new_phone
  end

  -- Update subscription active flag if passed
  if new_subscription_active ~= nil then
    if new_subscription_active == true or new_subscription_active == "true" then
      user.subscription_active = true
    elseif new_subscription_active == false or new_subscription_active == "false" then
      user.subscription_active = false
    end
  end

  -- Update subscription dates if passed (empty string clears the date)
  if new_subscription_start ~= nil then
    user.subscription_start_date = (new_subscription_start ~= "") and new_subscription_start or nil
  end
  if new_subscription_end ~= nil then
    user.subscription_end_date = (new_subscription_end ~= "") and new_subscription_end or nil
  end

  users[username] = user

  local ok, err = write_users(users)
  if not ok then
    return false, err
  end

  return true, "User updated"
end

return {
  -- Constants
  ROLES = ROLES,
  DEFAULT_ROLE = DEFAULT_ROLE,

  -- Functions
  create = create,
  login = login,
  find_by_username = find_by_username,
  is_valid_role = is_valid_role,
  delete_user = delete_user,
  update_user = update_user,
  record_login = record_login,
}
