require "kemal"
require "components/trends_page"
require "components/layout"
require "helpers/date_helper"
require "repositories/expense_repository"

LOG = Log.for("mercado.trends")

module TrendsStats
  extend self

  MONTHS = [
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December",
  ]

  private struct Period
    getter start_date : Time
    getter end_date : Time

    def initialize(@start_date : Time, @end_date : Time)
    end
  end

  def build(date_param : String?) : TrendsStatsViewModel
    now = Time.utc.in(DateHelper::SAO_PAULO)
    selected_month = parse_selected_month(date_param, now)
    current_month = month_start(now)
    is_current_month = same_month?(selected_month, current_month)

    target_period = if is_current_month
                      Period.new(selected_month, now)
                    else
                      Period.new(selected_month, selected_month.shift(months: 1))
                    end

    comparison_period = comparison_period_for(target_period, is_current_month)
    expenses = ExpenseRepository.between_dates(target_period.start_date, target_period.end_date)
    comparison_expenses = ExpenseRepository.between_dates(comparison_period.start_date, comparison_period.end_date)

    TrendsStatsViewModel.new(
      nav: TrendsMonthNav.new(
        selected_label: month_label(selected_month),
        previous_href: adjacent_href(selected_month, -1),
        next_href: adjacent_href(selected_month, 1),
        comparison_label: is_current_month ? "Mês passado" : "Anterior"
      ),
      total_row: money_row("Total gasto", total(expenses), total(comparison_expenses)),
      sections: sections(expenses, comparison_expenses, comparison_period),
      empty: expenses.empty?
    )
  end

  private def parse_selected_month(date_param : String?, now : Time) : Time
    parsed = if date_param && !date_param.empty?
               Time.parse(date_param, "%F", DateHelper::SAO_PAULO)
             else
               now
             end

    month_start(parsed)
  rescue
    month_start(now)
  end

  private def month_start(time : Time) : Time
    local = time.in(DateHelper::SAO_PAULO)
    Time.local(local.year, local.month, 1, 0, 0, 0, location: DateHelper::SAO_PAULO)
  end

  private def same_month?(left : Time, right : Time) : Bool
    left.year == right.year && left.month == right.month
  end

  private def comparison_period_for(target_period : Period, is_current_month : Bool) : Period
    comparison_start = target_period.start_date.shift(months: -1)
    comparison_end = if is_current_month
                       comparison_start + (target_period.end_date - target_period.start_date)
                     else
                       target_period.start_date
                     end

    Period.new(comparison_start, comparison_end)
  end

  private def adjacent_href(selected_month : Time, month_delta : Int32) : String?
    adjacent = selected_month.shift(months: month_delta)
    adjacent_end = adjacent.shift(months: 1)

    return nil unless ExpenseRepository.any_between_dates?(adjacent, adjacent_end)

    "/tendencias?date=#{date_param(adjacent)}"
  end

  private def date_param(month : Time) : String
    "#{month.year}-#{month.month.to_s.rjust(2, '0')}-01"
  end

  private def month_label(month : Time) : String
    "#{MONTHS[month.month - 1]} #{month.year}"
  end

  private def sections(expenses : Array(Expense), comparison_expenses : Array(Expense), comparison_period : Period) : Array(TrendsStatsSection)
    [
      TrendsStatsSection.new("Total gasto por mercado", money_rows_by_store(expenses, comparison_expenses, average: false)),
      TrendsStatsSection.new("Total gasto por dia", money_rows_by_day(expenses, comparison_expenses, comparison_period, average: false)),
      TrendsStatsSection.new("Média por mercado", money_rows_by_store(expenses, comparison_expenses, average: true)),
      TrendsStatsSection.new("Média por dia", money_rows_by_day(expenses, comparison_expenses, comparison_period, average: true)),
      TrendsStatsSection.new("Mercados mais visitados", count_rows_by_store(expenses, comparison_expenses)),
      TrendsStatsSection.new("Mercados por gasto", top_spending_rows_by_store(expenses, comparison_expenses)),
    ]
  end

  private def money_rows_by_store(expenses : Array(Expense), comparison_expenses : Array(Expense), average : Bool) : Array(TrendsComparisonRow)
    current = store_totals(expenses)
    previous = store_totals(comparison_expenses)
    visits = store_counts(expenses)
    previous_visits = store_counts(comparison_expenses)

    current.keys.sort.map do |store|
      current_value = average ? average(current[store], visits[store]) : current[store]
      previous_value = average ? average(previous.fetch(store, 0), previous_visits.fetch(store, 0)) : previous.fetch(store, 0)
      money_row(store, current_value, previous_value)
    end
  end

  private def money_rows_by_day(expenses : Array(Expense), comparison_expenses : Array(Expense), comparison_period : Period, average : Bool) : Array(TrendsComparisonRow)
    current = day_totals(expenses)
    previous = day_totals(comparison_expenses)
    visits = day_counts(expenses)
    previous_visits = day_counts(comparison_expenses)
    comparison_days = days_in_month(comparison_period.start_date)

    current.keys.sort.map do |day|
      current_value = average ? average(current[day], visits[day]) : current[day]
      previous_value = if day <= comparison_days
                         average ? average(previous.fetch(day, 0), previous_visits.fetch(day, 0)) : previous.fetch(day, 0)
                       end
      money_row("Dia #{day}", current_value, previous_value)
    end
  end

  private def count_rows_by_store(expenses : Array(Expense), comparison_expenses : Array(Expense)) : Array(TrendsComparisonRow)
    current = store_counts(expenses)
    previous = store_counts(comparison_expenses)

    current.to_a
      .sort_by { |entry| {-entry[1], entry[0]} }
      .map do |entry|
        store, visits = entry
        count_row(store, visits, previous.fetch(store, 0))
      end
  end

  private def top_spending_rows_by_store(expenses : Array(Expense), comparison_expenses : Array(Expense)) : Array(TrendsComparisonRow)
    current = store_totals(expenses)
    previous = store_totals(comparison_expenses)

    current.to_a
      .sort_by { |entry| {-entry[1], entry[0]} }
      .map do |entry|
        store, spent = entry
        money_row(store, spent, previous.fetch(store, 0))
      end
  end

  private def store_totals(expenses : Array(Expense)) : Hash(String, Int32)
    totals = Hash(String, Int32).new(0)
    expenses.each do |expense|
      totals[expense.grocery_store] += expense.value
    end
    totals
  end

  private def store_counts(expenses : Array(Expense)) : Hash(String, Int32)
    counts = Hash(String, Int32).new(0)
    expenses.each do |expense|
      counts[expense.grocery_store] += 1
    end
    counts
  end

  private def day_totals(expenses : Array(Expense)) : Hash(Int32, Int32)
    totals = Hash(Int32, Int32).new(0)
    expenses.each do |expense|
      day = expense.date.in(DateHelper::SAO_PAULO).day
      totals[day] += expense.value
    end
    totals
  end

  private def day_counts(expenses : Array(Expense)) : Hash(Int32, Int32)
    counts = Hash(Int32, Int32).new(0)
    expenses.each do |expense|
      day = expense.date.in(DateHelper::SAO_PAULO).day
      counts[day] += 1
    end
    counts
  end

  private def total(expenses : Array(Expense)) : Int32
    expenses.sum(0) { |expense| expense.value }
  end

  private def average(total : Int32, count : Int32) : Int32
    return 0 if count == 0

    (total / count).round.to_i
  end

  private def days_in_month(month : Time) : Int32
    local = month.in(DateHelper::SAO_PAULO)
    Time.days_in_month(local.year, local.month)
  end

  private def money_row(label : String, current : Int32, previous : Int32?) : TrendsComparisonRow
    unless previous
      return TrendsComparisonRow.new(
        label: label,
        current_value: format_money(current),
        previous_value: "-",
        delta: "-",
        delta_type: DeltaType::Zero
      )
    end

    delta = current - previous
    TrendsComparisonRow.new(
      label: label,
      current_value: format_money(current),
      previous_value: format_money(previous),
      delta: format_money_delta(delta),
      delta_type: delta_type(delta)
    )
  end

  private def count_row(label : String, current : Int32, previous : Int32) : TrendsComparisonRow
    delta = current - previous
    TrendsComparisonRow.new(
      label: label,
      current_value: "#{current}x",
      previous_value: "#{previous}x",
      delta: format_count_delta(delta),
      delta_type: delta_type(delta)
    )
  end

  private def format_money(cents : Int32) : String
    whole = cents // 100
    decimal = (cents % 100).abs
    "R$#{whole},#{decimal.to_s.rjust(2, '0')}"
  end

  private def format_money_delta(cents : Int32) : String
    sign = cents > 0 ? "+" : cents < 0 ? "-" : ""
    "#{sign}#{format_money(cents.abs)}"
  end

  private def format_count_delta(value : Int32) : String
    sign = value > 0 ? "+" : ""
    "#{sign}#{value}x"
  end

  private def delta_type(value : Int32) : DeltaType
    case
    when value < 0
      DeltaType::Negative
    when value > 0
      DeltaType::Positive
    else
      DeltaType::Zero
    end
  end
end

get "/tendencias" do |env|
  env.response.content_type = "text/html; charset=utf-8"

  stats = TrendsStats.build(env.params.query["date"]?)

  page = Layout::Main.new(
    TrendsPage.new(stats),
    "Tendências"
  )

  page.render(env.response)
end
