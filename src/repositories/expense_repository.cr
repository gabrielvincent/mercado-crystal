require "../models/expense"
require "../queries/expense_query"

module ExpenseRepository
  extend self

  def last_n_days(days : Int32) : Array(Expense)
    cutoff = Time.utc - days.days
    ExpenseQuery.new.date.gte(cutoff).date.desc_order.results
  end

  def between_dates(start_date : Time, end_date : Time) : Array(Expense)
    ExpenseQuery.new.date.gte(start_date).date.lt(end_date).date.asc_order.results
  end

  def any_between_dates?(start_date : Time, end_date : Time) : Bool
    !ExpenseQuery.new.date.gte(start_date).date.lt(end_date).first?.nil?
  end

  def earliest_date : Time?
    ExpenseQuery.new.date.select_min
  end

  def latest_date : Time?
    ExpenseQuery.new.date.select_max
  end

  def find(id : Int64) : Expense?
    ExpenseQuery.new.id(id).first?
  end

  def update_by_id_returning(id : Int64, value : Int32, grocery_store : String) : Expense?
    ExpenseQuery.new.id(id).update_returning(value: value, grocery_store: grocery_store)
  end
end
