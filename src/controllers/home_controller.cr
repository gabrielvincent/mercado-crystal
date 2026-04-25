require "kemal"
require "../components/home_page"
require "../components/layout"
require "../helpers/htmx_helper"
require "../repositories/expense_repository"
require "../services/expense_service"

EXPENSE_LOG = Log.for("mercado.expense")

get "/" do |env|
  env.response.content_type = "text/html; charset=utf-8"

  expenses_chan = Channel(Component).new

  spawn do
    begin
      expenses = ExpenseRepository.last_n_days(50)

      expenses_chan.send(ExpensesList.new(expenses))
    rescue e
      EXPENSE_LOG.error { "stream_expenses_error session_user_id=#{env.session.bigint?("user_id")} session_id=#{env.session.id} error=#{e.message}" }
      expenses_chan.send(ExpensesList.error)
    end
  end

  page = Layout::Main.new(
    HomePage.new(
      Component.async(expenses_chan, ExpensesList.loading)
    ),
    "Gastos"
  )

  page.render(env.response)
end

post "/" do |env|
  env.response.content_type = "text/html; charset=utf-8"
  begin
    expense = ExpenseService.create(
      env.params.body["value"]?.to_s,
      env.params.body["grocery-store"]?.to_s,
    )
    ExpenseListItem.new(expense).to_s
  rescue e : ExpenseService::ValidationError
    HtmxHelper.retarget(env, "find span.error-message")
    e.message || "Erro de validação"
  rescue e
    HtmxHelper.retarget(env, "find span.error-message")
    "Falha ao adicionar"
  end
end

post "/edit/:id" do |env|
  env.response.content_type = "text/html; charset=utf-8"
  id_str = env.params.url["id"]
  id = id_str.to_i64?
  raw_value = env.params.body["value"]?
  session_user_id = env.session.bigint?("user_id")

  EXPENSE_LOG.info { "edit_expense_attempt expense_id=#{id_str} session_user_id=#{session_user_id} session_id=#{env.session.id}" }

  if raw_value.nil? || raw_value.empty?
    EXPENSE_LOG.warn { "edit_expense_invalid_value expense_id=#{id_str} session_user_id=#{session_user_id} session_id=#{env.session.id}" }
    raise ArgumentError.new("value is required")
  end
  halt env, status_code: 400, response: "Error!" unless id

  begin
    expense = ExpenseService.edit(
      id,
      env.params.body["value"]?.to_s,
      env.params.body["grocery-store"]?.to_s,
    )
    EXPENSE_LOG.info { "edit_expense_success expense_id=#{id} session_user_id=#{session_user_id} session_id=#{env.session.id}" }
    ExpenseListItem.new(expense).to_s
  rescue e : ExpenseService::ValidationError
    EXPENSE_LOG.warn { "edit_expense_validation_error expense_id=#{id} session_user_id=#{session_user_id} session_id=#{env.session.id} error=#{e.message}" }
    e.message || "Erro de validação"
  rescue e
    EXPENSE_LOG.error { "edit_expense_error expense_id=#{id} session_user_id=#{session_user_id} session_id=#{env.session.id} error=#{e.message}" }
    "Falha ao editar"
  end
end

delete "/:id" do |env|
  id = env.params.url["id"].to_i64?
  halt env, status_code: 200, response: "Error!" unless id

  if ExpenseService.delete(id.not_nil!)
    env.response.status_code = 200
    ""
  else
    "Falha ao apagar!"
  end
end
