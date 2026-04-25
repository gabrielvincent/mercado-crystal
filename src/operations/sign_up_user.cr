require "crypto/bcrypt/password"
require "../models/user"

class SignUpUser < User::SaveOperation
  param_key :user
  attribute password : String

  before_save do
    validate_required email, password
    validate_format_of email, with: /@/
    validate_size_of password, min: 8

    if pw = password.value
      encrypted_password.value = Crypto::Bcrypt::Password.create(pw).to_s
    end
  end
end
