require "../lib/component"

class AuthPage < Component
  def initialize(@error_msg : String = "")
  end

  view do
    div class: "min-h-screen flex items-center justify-center bg-gray-100" do
      form(
        method: "POST",
        action: "/login",
        class: "max-w-sm w-full bg-white shadow-md rounded-md px-8 pt-6 pb-8 mb-4"
      ) do
        unless @error_msg.empty?
          div class: "mb-4" do
            span @error_msg, id: "error-message", class: "block text-rose-500"
          end
        end

        div class: "mb-4" do
          label "Email", for: "email", class: "block text-gray-700 text-sm font-bold mb-2"
          input(
            id: "email",
            name: "email",
            type: "email",
            autocomplete: "email",
            autofocus: true,
            class: "w-full px-3 py-2 border rounded-md focus:outline-none focus:border-blue-500"
          )
        end

        div class: "mb-4" do
          label "Senha", for: "password", class: "block text-gray-700 text-sm font-bold mb-2"
          input(
            id: "password",
            name: "password",
            type: "password",
            placeholder: "******",
            autocomplete: "current-password",
            class: "w-full px-3 py-2 border rounded-md focus:outline-none focus:border-blue-500"
          )
        end

        button "Login",
          type: "submit",
          class: "w-full bg-blue-500 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition duration-300"
      end
    end
  end
end
