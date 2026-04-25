require "../constants/grocery_stores"
require "../helpers/currency_helper"
require "../models/expense"
require "../operations/delete_expense"
require "../operations/save_expense"
require "../repositories/expense_repository"

module ExpenseService
  extend self

  class ValidationError < Exception
  end

  def create(value_str : String?, grocery_store : String?) : Expense
    cents = parse_value!(value_str)
    store = validate_store!(grocery_store)
    SaveExpense.create!(
      value: cents,
      grocery_store: store,
      date: Time.utc,
    )
  end

  def edit(id : Int64, value_str : String?, grocery_store : String?) : Expense
    cents = parse_value!(value_str)
    store = validate_store!(grocery_store)
    expense = ExpenseRepository.update_by_id_returning(id, value: cents, grocery_store: store)
    raise ValidationError.new("Despesa não encontrada") unless expense
    expense
  end

  def delete(id : Int64) : Bool
    expense = ExpenseRepository.find(id)
    return false unless expense
    DeleteExpense.delete!(expense)
    true
  end

  private def parse_value!(value_str : String?) : Int32
    raise ValidationError.new("O valor deve ser informado") if value_str.nil? || value_str.strip.empty?
    value_f = value_str.to_f?
    raise ValidationError.new("O valor deve ser informado") if value_f.nil?
    cents = CurrencyHelper.parse_cents(value_f)
    raise ValidationError.new("O valor deve ser positivo e não-zero") if cents.nil? || cents <= 0
    cents
  end

  private def validate_store!(store : String?) : String
    raise ValidationError.new("Véi, seleciona um mercado 😤") if store.nil? || store.empty?
    raise ValidationError.new("Nome de mercado inválido: #{store}") unless GROCERY_STORES.includes?(store)
    store
  end
end
