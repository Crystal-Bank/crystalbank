require "./concerns/responses"

module CrystalBank::Domains::Platform
  module Api
    class Platform < CrystalBank::Api::Base
      include CrystalBank::Domains::Platform::Api::Responses
      base "/platform"

      # Reset
      # Reset the platform and re-seed with initial data.
      # Returns credentials for the two seeded admin users.
      #
      # Required permission:
      # - **write_platform_reset_request**
      @[AC::Route::POST("/reset")]
      def reset : ResetResponse
        authorized?("write_platform_reset_request", request_scope: false)

        CrystalBank::Domains::Platform::Reset::Commands::Request.new.call
      end
    end
  end
end
