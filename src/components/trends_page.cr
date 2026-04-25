require "../lib/component"
require "./home_page"

enum DeltaType
  Positive
  Negative
  Zero
end

record TrendsComparisonRow,
  label : String,
  current_value : String,
  previous_value : String,
  delta : String,
  delta_type : DeltaType

record TrendsStatsSection,
  title : String,
  rows : Array(TrendsComparisonRow)

record TrendsMonthNav,
  selected_label : String,
  previous_href : String?,
  next_href : String?,
  comparison_label : String

record TrendsStatsViewModel,
  nav : TrendsMonthNav,
  total_row : TrendsComparisonRow,
  sections : Array(TrendsStatsSection),
  empty : Bool

class TrendsPage < Component
  props stats : TrendsStatsViewModel

  view do
    div class: "mx-auto max-w-sm px-4 pb-28 pt-6" do
      child TrendsMonthNavigator.new(stats.nav)

      if stats.empty
        p "Nenhuma despesa encontrada para este mês.", class: "mt-8 rounded-md bg-gray-100 p-4 text-sm text-gray-500"
      else
        div class: "mt-6" do
          child TrendsFeaturedStat.new(stats.total_row, stats.nav.comparison_label)
        end

        div class: "mt-6 space-y-6" do
          stats.sections.each do |section|
            child TrendsStatsSectionComponent.new(section, stats.nav.comparison_label)
          end
        end
      end
    end

    child BottomTabBar.new("trends")
  end
end

class TrendsMonthNavigator < Component
  props nav : TrendsMonthNav

  view do
    div class: "flex items-center justify-center gap-4" do
      if previous_href = nav.previous_href
        a "<", href: previous_href, class: "px-2 py-1 text-2xl font-bold text-gray-800"
      else
        span "<", class: "px-2 py-1 text-2xl font-bold text-gray-300"
      end

      h1 nav.selected_label, class: "min-w-48 text-center text-2xl font-bold"

      if next_href = nav.next_href
        a ">", href: next_href, class: "px-2 py-1 text-2xl font-bold text-gray-800"
      else
        span ">", class: "px-2 py-1 text-2xl font-bold text-gray-300"
      end
    end
  end
end

class TrendsFeaturedStat < Component
  props row : TrendsComparisonRow,
    comparison_label : String

  view do
    section class: "rounded-md bg-gray-900 p-4 text-white" do
      div class: "text-sm text-gray-300" do
        text row.label
      end

      div class: "mt-2 text-3xl font-bold" do
        text row.current_value
      end

      div class: "mt-3 grid grid-cols-2 gap-2 text-sm" do
        div do
          div comparison_label, class: "text-gray-400"
          div row.previous_value, class: "font-semibold"
        end

        div class: "text-right" do
          div "Diferença", class: "text-gray-400"
          div row.delta, class: "font-semibold #{delta_class(row)}"
        end
      end
    end
  end

  private def delta_class(row : TrendsComparisonRow) : String
    case row.delta_type
    when "positive"
      "text-rose-300"
    when "negative"
      "text-emerald-300"
    else
      "text-gray-300"
    end
  end
end

class TrendsStatsSectionComponent < Component
  props section : TrendsStatsSection,
    comparison_label : String

  view do
    section do
      h2 section.title, class: "mb-3 text-lg font-bold"

      if section.rows.empty?
        p "Sem dados para mostrar.", class: "rounded-md bg-gray-100 p-3 text-sm text-gray-500"
      else
        div class: "overflow-hidden rounded-md border border-gray-200" do
          div class: "grid grid-cols-[1fr_5rem_5rem_4rem] gap-2 bg-gray-100 px-3 py-2 text-xs font-bold text-gray-500" do
            span "Item"
            span "Atual", class: "text-right"
            span comparison_label, class: "text-right"
            span "Dif.", class: "text-right"
          end

          section.rows.each do |row|
            child TrendsStatsRowComponent.new(row)
          end
        end
      end
    end
  end
end

class TrendsStatsRowComponent < Component
  props row : TrendsComparisonRow

  view do
    div class: "grid grid-cols-[1fr_5rem_5rem_4rem] gap-2 border-t border-gray-100 px-3 py-2 text-sm" do
      span row.label, class: "min-w-0 truncate text-gray-800"
      span row.current_value, class: "text-right font-semibold"
      span row.previous_value, class: "text-right text-gray-500"
      span row.delta, class: "text-right font-semibold #{delta_class(row)}"
    end
  end

  private def delta_class(row : TrendsComparisonRow) : String
    case row.delta_type
    when DeltaType::Positive
      "text-rose-600"
    when DeltaType::Negative
      "text-emerald-600"
    else
      "text-gray-500"
    end
  end
end
