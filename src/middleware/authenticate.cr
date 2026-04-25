require "kemal"
require "../services/auth_service"

before_all do |env|
  path = env.request.path

  next if env.response.closed?
  next if {"/login", "/logout"}.includes?(path)
  next if path.starts_with?("/css/") ||
          path.starts_with?("/js/") ||
          path.starts_with?("/images/") ||
          path.starts_with?("/fonts/") ||
          path.starts_with?("/.well-known/") ||
          path == "/favicon.ico"

  unless AuthService.authenticated?(env)
    env.redirect("/login")
    next
  end
end
