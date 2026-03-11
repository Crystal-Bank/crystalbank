module CrystalBank
  module Api
    # Serves the embedded frontend SPA.
    # Extends AC::Base directly — no authentication required to load the UI.
    # All API calls are made from the browser using the same origin.
    class Frontend < ::AC::Base
      base "/"

      INDEX_HTML = {{ read_file("#{__DIR__}/../../public/index.html") }}

      get "/" do
        response.content_type = "text/html; charset=utf-8"
        response.print INDEX_HTML
        response.close
      end
    end
  end
end
