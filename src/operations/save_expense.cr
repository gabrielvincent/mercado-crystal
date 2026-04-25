require "../models/expense"

class SaveExpense < Expense::SaveOperation
  param_key :expense

  before_save do
    validate_required value, grocery_store, date
  end
end
