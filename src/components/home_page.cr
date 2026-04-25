require "../constants/grocery_stores"
require "../helpers/currency_helper"
require "../helpers/date_helper"
require "../lib/component"
require "../models/expense"
require "./icons"

class HomePage < Component
  props expenses : Component

  view do
    div class: "pb-28" do
      form(
        id: "add-form",
        hx_target: "#expenses-list",
        hx_post: "/",
        hx_swap: "afterbegin",
        x_data: "{ expenseValue: undefined, adding: false }",
        x_init: "handleFormInit",
        class: "sticky top-0 mx-auto max-w-sm rounded-md bg-white p-4 shadow-md"
      ) do
        div class: "mb-4" do
          label "Valor", for: "value", class: "mb-2 block text-sm font-bold text-gray-700"
          input(
            id: "value",
            name: "value",
            placeholder: "É de quanto, é de quanto?",
            type: "text",
            inputmode: "decimal",
            x_model: "expenseValue",
            ":value": "expenseValue",
            "@input": "handleInputChange",
            class: "w-full rounded-md border px-3 py-2 focus:border-blue-500 focus:outline-none"
          )
        end

        div class: "mb-4" do
          child GroceryStoreSelector.new("", true)
        end

        button(
          id: "add-button",
          type: "submit",
          class: "w-full rounded-md px-4 py-2 text-white transition duration-300",
          ":class": "{ 'bg-blue-500 hover:bg-blue-700': expenseValue && !adding, 'bg-blue-200': !expenseValue, 'bg-gray-300': adding }",
          ":disabled": "adding || !expenseValue"
        ) do
          span "Resistrando...", x_show: "adding"
          span "Resistrar", x_show: "!adding"
        end

        span class: "error-message mt-4 block text-rose-500 empty:hidden"
      end

      div class: "mt-8"
      div class: "mb-4 flex items-center justify-between px-4" do
        h2 "Despesas", class: "text-xl font-bold"
      end

      child expenses
    end

    child BottomTabBar.new("expenses")
  end
end

class ExpensesList < Component
  props expenses : Array(Expense)

  view do
    ul id: "expenses-list" do
      if expenses.empty?
        li "Nenhuma despesa (ainda)", class: "px-4"
      else
        expenses.each do |expense|
          child ExpenseListItem.new(expense)
        end
      end
    end
  end

  def self.loading : Component
    Loading.new
  end

  def self.error : Component
    Error.new
  end

  class Loading < Component
    view do
      ul id: "expenses-list" do
        8.times do
          li class: "mb-4 rounded p-4 shadow-md" do
            div class: "flex animate-pulse" do
              div class: "flex-1" do
                div class: "mb-2 h-5 w-24 rounded bg-gray-200"
                div class: "h-3 w-32 rounded bg-gray-100"
              end

              div class: "h-8 w-16 rounded bg-gray-100"
            end
          end
        end
      end
    end
  end

  class Error < Component
    view do
      ul id: "expenses-list" do
        li "Falha ao carregar despesas", class: "px-4 text-rose-500"
      end
    end
  end
end

class ExpenseListItem < Component
  props expense : Expense

  view do
    value = CurrencyHelper.format(expense.value)
    input_value = format_input_value(expense.value)
    grocery_store = expense.grocery_store
    date = DateHelper.format_br(expense.date)

    li(
      class: "expense-list-item p-4 mb-4 rounded shadow-md",
      x_data: "{ editing: false }"
    ) do
      dialog class: "rounded" do
        div class: "p-8" do
          h3 "Certzinha que quer deletar isso?"
          div class: "flex items-center space-x-6 mt-3" do
            button "Melhor não", "@click": "handleCancelDelete($event)", class: "text-blue-500 p-2"
            button(
              "Sim, Deletar",
              class: "text-red-500 p-2",
              hx_delete: "/#{expense.id}",
              hx_target: "closest .expense-list-item",
              hx_swap: "outerHTML"
            )
          end
        end
      end

      div x_show: "!editing", class: "flex" do
        div class: "flex-1" do
          div class: "flex items-center space-x-2" do
            span value, class: "text-lg font-semibold"
            div grocery_store, class: "text-gray-600"
          end

          span date, class: "text-xs"
        end

        div class: "flex space-x-4 items-center" do
          button(
            "Editar",
            "@click": "editing = true; $nextTick(() => $el.closest('.expense-list-item')?.querySelector('input[name=\"value\"]')?.focus())",
            class: "ml-auto text-blue-500"
          )
          button "@click": "handleDelete($event)", class: "text-red-500 flex items-center space-x-1" do
            child Icons::Trash.new
          end
        end
      end

      div x_cloak: true, x_show: "editing", class: "mt-2" do
        form(
          hx_post: "/edit/#{expense.id}",
          hx_target: "closest .expense-list-item",
          hx_swap: "outerHTML"
        ) do
          span do
            label "Valor", for: "value", class: "block text-sm font-medium mb-1"
            div x_data: %({ expenseValue: "#{input_value}" }) do
              input(
                name: "value",
                "@input": "handleInputChange",
                x_model: "expenseValue",
                value: input_value,
                type: "text",
                inputmode: "decimal",
                class: "w-full border border-gray-300 px-2 py-1 rounded"
              )

              div class: "mt-2" do
                child GroceryStoreSelector.new(expense.grocery_store, false)
              end
            end
          end

          button "Salvar",
            type: "submit",
            class: "w-full mt-2 px-4 py-2 bg-blue-500 text-white rounded"
        end
      end
    end
  end

  private def format_input_value(cents : Int32) : String
    whole = cents // 100
    decimal = (cents % 100).abs
    "#{whole}.#{decimal.to_s.rjust(2, '0')}"
  end
end

class GroceryStoreSelector < Component
  props selected : String, show_header : Bool

  view do
    label "Mercado", for: "grocery-store", class: "mb-2 block text-sm font-bold text-gray-700"
    tag(
      "select",
      id: "grocery-store",
      name: "grocery-store",
      class: "w-full rounded-md border px-3 h-11 focus:border-blue-500 focus:outline-none"
    ) do
      option "Tá em ordem alfabética 👇", value: "" if show_header

      GROCERY_STORES.each do |store|
        option store, value: store, selected: selected == store
      end
    end
  end
end

class BottomTabBar < Component
  props active : String

  view do
    expenses_class = tab_class(active, "expenses")
    trends_class = tab_class(active, "trends")

    nav(
      class: "fixed inset-x-0 bottom-0 z-50 border-t border-gray-200 bg-white/95 px-4 pb-[calc(0.75rem+env(safe-area-inset-bottom))] pt-3 shadow-[0_-10px_30px_rgba(15,23,42,0.08)] backdrop-blur",
      aria_label: "Navegação principal"
    ) do
      div class: "mx-auto grid max-w-sm grid-cols-3 gap-2" do
        a "Despesas",
          href: "/",
          class: "rounded-xl px-3 py-3 text-center text-sm font-bold transition #{expenses_class}"

        a "Tendências",
          href: "/tendencias",
          class: "rounded-xl px-3 py-3 text-center text-sm font-bold transition #{trends_class}"

        form(
          method: "POST",
          action: "/logout",
          x_data: "{ confirmingLogout: false, logoutTimer: undefined }",
          "@submit": "
            if (!confirmingLogout) {
              $event.preventDefault();
              confirmingLogout = true;
              clearTimeout(logoutTimer);
              logoutTimer = setTimeout(() => confirmingLogout = false, 3000);
            }
          "
        ) do
          button(
            type: "submit",
            class: "logout-button text-gray-500 h-full w-full rounded-xl px-3 py-3 text-center text-sm font-bold transition",
            ":data-confirming-logout": "confirmingLogout"
          ) do
            span "Sair", x_show: "!confirmingLogout"
            span "Sair?", x_cloak: true, x_show: "confirmingLogout"
          end
        end
      end
    end

    css <<-CSS
        .logout-button {
          &:hover {
            color: var(--color-rose-500);
          }

          &[data-confirming-logout="true"] {
            background: var(--color-rose-600)
            color: var(--color-gray-50);
          }
        }
      CSS
  end

  private def tab_class(active : String, tab : String) : String
    if active == tab
      "bg-gray-900 text-white"
    else
      "text-gray-500 hover:bg-gray-100 hover:text-gray-900"
    end
  end
end
