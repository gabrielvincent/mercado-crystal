require "avram"

require "../../src/config/database"
require "../../src/models/user"
require "../../src/queries/user_query"
require "../../src/operations/sign_up_user"

email = ENV["SEED_USER_EMAIL"]? || "demo@example.com"
password = ENV["SEED_USER_PASSWORD"]? || "ChangeMe123!"

if UserQuery.new.email(email).first?
  puts "User already exists for #{email}"
  exit 0
end

SignUpUser.create(email: email, password: password) do |operation, user|
  if user
    puts "Created user #{user.email}"
  else
    puts "Failed to create user #{email}"
    pp operation.errors
    exit 1
  end
end
