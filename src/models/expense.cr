require "avram"
require "../config/database"

class Expense < Avram::Model
  def self.database : Avram::Database.class
    AppDatabase
  end

  table :expenses do
    column value : Int32
    column grocery_store : String
    column date : Time
  end
end
