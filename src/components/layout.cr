require "../lib/component"

module Layout
  class BaseLayout < Component
    props child : Component,
      title : String,
      head_tags : Array(Component)

    view do
      raw "<!DOCTYPE html>"
      html lang: "pt-BR" do
        head do
          meta charset: "UTF-8"
          meta name: "viewport", content: "width=device-width, initial-scale=1.0"
          meta name: "mobile-web-app-capable", content: "yes"
          meta name: "apple-mobile-web-app-capable", content: "yes"
          meta name: "apple-mobile-web-app-title", content: "Mercado"
          link rel: "manifest", href: "/manifest.webmanifest"
          link rel: "apple-touch-icon", href: "/images/icon.png"
          meta name: "apple-mobile-web-app-status-bar-style", content: "black"
          title title
          link rel: "stylesheet", href: "/css/custom-fonts.css"
          link rel: "stylesheet", href: "/css/tailwind.css"

          head_tags.each do |head_tag|
            child head_tag
          end
        end

        body do
          main do
            child child
          end
        end
      end
    end
  end

  class Main < BaseLayout
    def initialize(child : Component, title : String)
      super(child, title, [MainHeadTags.new] of Component)
    end
  end

  class Auth < BaseLayout
    def initialize(child : Component, title : String)
      super(child, title, [] of Component)
    end
  end

  private class MainHeadTags < Component
    view do
      script src: "/js/htmx.min.js"
      script src: "/js/alpinejs.min.js", defer: true
      script src: "/js/home.js"
    end
  end
end
