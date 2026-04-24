module CrystalBank::Domains::Credentials
  class Aggregate < ES::Aggregate
    @@type = "Credential"

    struct State < ES::Aggregate::State
      property status : String = "pending_setup"
      property password_hash : String?
      property invitation_token_hash : String?
      property invitation_expires_at : Time?
      property reset_token_hash : String?
      property reset_expires_at : Time?
      property totp_encrypted_secret : String?
      property totp_active : Bool = false
    end

    getter state : State

    def initialize(
      aggregate_id : UUID,
      @event_store : ES::EventStore = ES::Config.event_store,
      @event_handlers : ES::EventHandlers = ES::Config.event_handlers,
    )
      @aggregate_version = 0
      @state = State.new(aggregate_id)
      @state.set_type(@@type)
    end

    def apply(event : Credentials::Invitation::Events::Sent)
      @state.increase_version(event.header.aggregate_version)
      body = event.body.as(Credentials::Invitation::Events::Sent::Body)
      @state.invitation_token_hash = body.token_hash
      @state.invitation_expires_at = body.expires_at
    end

    def apply(event : Credentials::PasswordSetup::Events::Completed)
      @state.increase_version(event.header.aggregate_version)
      body = event.body.as(Credentials::PasswordSetup::Events::Completed::Body)
      @state.password_hash = body.password_hash
      @state.status = "active"
      @state.invitation_token_hash = nil
      @state.invitation_expires_at = nil
    end

    def apply(event : Credentials::PasswordReset::Events::Requested)
      @state.increase_version(event.header.aggregate_version)
      body = event.body.as(Credentials::PasswordReset::Events::Requested::Body)
      @state.reset_token_hash = body.token_hash
      @state.reset_expires_at = body.expires_at
    end

    def apply(event : Credentials::PasswordReset::Events::Confirmed)
      @state.increase_version(event.header.aggregate_version)
      body = event.body.as(Credentials::PasswordReset::Events::Confirmed::Body)
      @state.password_hash = body.password_hash
      @state.reset_token_hash = nil
      @state.reset_expires_at = nil
    end

    def apply(event : Credentials::Totp::Events::SetupInitiated)
      @state.increase_version(event.header.aggregate_version)
      body = event.body.as(Credentials::Totp::Events::SetupInitiated::Body)
      @state.totp_encrypted_secret = body.encrypted_secret
    end

    def apply(event : Credentials::Totp::Events::Enabled)
      @state.increase_version(event.header.aggregate_version)
      @state.totp_active = true
    end
  end
end
