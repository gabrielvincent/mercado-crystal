require "avram"
require "../config/database"

class User < Avram::Model
  def self.database : Avram::Database.class
    AppDatabase
  end

  table :users do
    column email : String
    column encrypted_password : String
  end
end
