require "../models/expense"

class ExpenseQuery < Expense::BaseQuery
  def update_returning(value : Int32, grocery_store : String) : Expense?
    changes = {} of Symbol => String?
    changes[:value] = Int32.adapter.to_db(value).to_s
    changes[:grocery_store] = String.adapter.to_db(grocery_store).to_s

    write_database.query(
      query.statement_for_update(changes),
      args: query.args_for_update(changes)
    ) do |rs|
      Expense.from_rs(rs).first?
    end
  end
end
