require "kemal"

require "./config/database"
require "./config/session"
require "./config/redis_session_ttl"
require "./config/static_assets"

require "./middleware/authenticate"

require "./controllers/auth_controller"
require "./controllers/home_controller"
require "./controllers/trends_controller"

public_folder "./public"

Kemal.config.host_binding = ENV.fetch("HOST", "0.0.0.0")
Kemal.config.port = ENV.fetch("PORT", "3000").to_i

Kemal.run
