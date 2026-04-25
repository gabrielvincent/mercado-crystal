require "kemal-session"
require "kemal-session-redis-engine"

Kemal::Session.config do |c|
  c.secret      = ENV["SESSION_SECRET"]
  c.cookie_name = "mercado_session"
  c.timeout     = 2.weeks
  c.samesite    = HTTP::Cookie::SameSite::Lax
  c.secure      = ENV.fetch("STAGE", "dev") == "prod"
  c.engine      = Kemal::Session::RedisEngine.new(
    ENV["REDIS_URL"],
    key_prefix: "mercado:session:"
  )
end
