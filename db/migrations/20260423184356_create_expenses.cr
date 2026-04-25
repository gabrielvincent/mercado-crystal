class CreateExpenses::V20260423184356 < Avram::Migrator::Migration::V1
  def migrate
    create :expenses do
      primary_key id : Int64
      add_timestamps
      add value : Int32
      add grocery_store : String
      add date : Time
    end
  end

  def rollback
    drop :expenses
  end
end
