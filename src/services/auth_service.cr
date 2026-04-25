require "crypto/bcrypt/password"
require "../models/user"
require "../repositories/user_repository"

module AuthService
  extend self

  def authenticate(env, email : String, password : String) : User?
    user = UserRepository.find_by_email(email)
    return nil unless user
    return nil unless Crypto::Bcrypt::Password.new(user.encrypted_password).verify(password)
    env.session.bigint("user_id", user.id)
    user
  end

  def authenticated?(env) : Bool
    !env.session.bigint?("user_id").nil?
  end

  def logout(env)
    env.session.destroy
  end
end
