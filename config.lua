local config = require("lapis.config")

config("development", {
  server = "nginx",
  code_cache = "off",
  num_workers = "1",
  port = "8080",
})

config("production", {
  server = "nginx",
  code_cache = "on",
  num_workers = "auto",
  port = os.getenv("PORT") or "8080",
  secret = os.getenv("SESSION_SECRET") or "change-me-in-production",
})
