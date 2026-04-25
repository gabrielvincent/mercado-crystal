require "avram"

class AppDatabase < Avram::Database
end

AppDatabase.configure do |settings|
  settings.credentials = Avram::Credentials.parse(ENV["DATABASE_CONNECTION_STRING"])
end

Avram.configure do |settings|
  settings.database_to_migrate = AppDatabase
  settings.lazy_load_enabled = true
end
