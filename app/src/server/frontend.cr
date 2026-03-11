module CrystalBank
  module Api
    # Serves the embedded frontend SPA.
    # Extends AC::Base directly — no authentication required to load the UI.
    # All three assets are read at compile time and stored as string constants,
    # so the binary carries the full frontend without any runtime file access.
    class Frontend < ::AC::Base
      base "/"

      INDEX_HTML = {{ read_file("#{__DIR__}/../../public/index.html") }}
      APP_JS     = {{ read_file("#{__DIR__}/../../public/app.js") }}
      APP_CSS    = {{ read_file("#{__DIR__}/../../public/style.css") }}

      get "/" do
        response.content_type = "text/html; charset=utf-8"
        response.print INDEX_HTML
        response.close
      end

      get "/app.js" do
        response.content_type = "application/javascript; charset=utf-8"
        response.print APP_JS
        response.close
      end

      get "/style.css" do
        response.content_type = "text/css; charset=utf-8"
        response.print APP_CSS
        response.close
      end
    end
  end
end
