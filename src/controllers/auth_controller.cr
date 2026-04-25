require "kemal"
require "../components/auth_page"
require "../components/layout"
require "../services/auth_service"

AUTH_LOG = Log.for("mercado.auth")

get "/login" do |env|
  if AuthService.authenticated?(env)
    env.redirect "/"
    next
  end

  env.response.content_type = "text/html; charset=utf-8"
  page = Layout::Auth.new(AuthPage.new, "Mercado")
  page.render(env.response)
end

post "/login" do |env|
  email = env.params.body["email"]?.to_s
  password = env.params.body["password"]?.to_s

  AUTH_LOG.info { "login_attempt email=#{email} session_id=#{env.session.id}" }

  user = AuthService.authenticate(env, email, password)
  session_user_id = env.session.bigint?("user_id")

  if user
    AUTH_LOG.info { "login_success email=#{email} user_id=#{user.id} session_user_id=#{session_user_id} session_id=#{env.session.id}" }
    env.redirect "/"
  else
    AUTH_LOG.warn { "login_failed email=#{email} session_user_id=#{session_user_id} session_id=#{env.session.id}" }
    env.response.content_type = "text/html; charset=utf-8"
    env.response.status_code = 401
    page = Layout::Auth.new(AuthPage.new("Email ou senha inválidos."), "Mercado")
    page.render(env.response)
  end
end

post "/logout" do |env|
  session_user_id = env.session.bigint?("user_id")
  AUTH_LOG.info { "logout session_user_id=#{session_user_id} session_id=#{env.session.id}" }
  AuthService.logout(env)
  env.redirect "/login"
end
