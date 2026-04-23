module CrystalBank
  module Api
    # Serves the embedded frontend SPA.
    # Extends AC::Base directly — no authentication required to load the UI.
    # All three assets are read at compile time and stored as string constants,
    # so the binary carries the full frontend without any runtime file access.
    class Frontend < ::AC::Base
      base "/"

      INDEX_HTML        = {{ read_file("#{__DIR__}/../../public/index.html") }}
      APP_JS            = {{ read_file("#{__DIR__}/../../public/app.js") }}
      APP_CSS           = {{ read_file("#{__DIR__}/../../public/style.css") }}
      APP_LOGO_SVG      = {{ read_file("#{__DIR__}/../../public/images/logo/crystalbank-horizontal-dark.svg") }}
      APP_FACICON_ICO   = {{ read_file("#{__DIR__}/../../public/images/logo/crystalbank-favicon.ico") }}
      APP_FAVICON_SVG   = {{ read_file("#{__DIR__}/../../public/images/logo/crystalbank-favicon.svg") }}
      APP_FAVICON32_png = {{ read_file("#{__DIR__}/../../public/images/logo/crystalbank-favicon-32x32.png") }}
      APP_FAVICON16_png = {{ read_file("#{__DIR__}/../../public/images/logo/crystalbank-favicon-16x16.png") }}

      @[AC::Route::Filter(:before_action)]
      def check_dashboard_domain
        host = (request.headers["Host"]? || "").split(":").first
        return if host == CrystalBank::Env.dashboard_domain
        response.status_code = 404
        response.close
      end

      get "/" do
        response.content_type = "text/html; charset=utf-8"
        api_url_script = %(<script>window.__API_URL__=#{CrystalBank::Env.api_base_url.to_json}</script>)
        response.print INDEX_HTML.sub("</head>", "#{api_url_script}</head>")
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

      get "/images/logo/crystalbank-favicon.ico" do
        response.content_type = "image/x-icon"
        response.print APP_FACICON_ICO
        response.close
      end

      get "/images/logo/crystalbank-favicon.svg" do
        response.content_type = "image/svg+xml; charset=utf-8"
        response.print APP_FAVICON_SVG
        response.close
      end

      get "/images/logo/crystalbank-favicon-32x32.png" do
        response.content_type = "image/png"
        response.print APP_FAVICON32_png
        response.close
      end

      get "/images/logo/crystalbank-favicon-16x16.png" do
        response.content_type = "image/png"
        response.print APP_FAVICON16_png
        response.close
      end

      get "/images/logo/crystalbank-horizontal-dark.svg" do
        response.content_type = "image/svg+xml; charset=utf-8"
        response.print APP_LOGO_SVG
        response.close
      end
    end
  end
end
