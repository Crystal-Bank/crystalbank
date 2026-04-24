require "email"

module CrystalBank
  module Services
    class Mailer
      def send_invitation(to_email : String, to_name : String, token : String)
        setup_link = "#{CrystalBank::Env.dashboard_domain}/#setup-password?token=#{token}"
        message = EMail::Message.new
        message.from(CrystalBank::Env.smtp_from)
        message.to(to_email, to_name)
        message.subject("Welcome to CrystalBank — Set up your password")
        message.message(<<-BODY
Welcome #{to_name},

You've been invited to CrystalBank. Click the link below to set your password:

#{setup_link}

This link expires in 7 days. If you didn't expect this email, please ignore it.
BODY
        )
        send!(message)
      end

      def send_password_reset(to_email : String, token : String)
        reset_link = "#{CrystalBank::Env.dashboard_domain}/#reset-password?token=#{token}"
        message = EMail::Message.new
        message.from(CrystalBank::Env.smtp_from)
        message.to(to_email)
        message.subject("CrystalBank — Reset your password")
        message.message(<<-BODY
Someone (hopefully you) requested a password reset for your CrystalBank account.

Click the link below to set a new password:

#{reset_link}

This link expires in 1 hour. If you didn't request this, you can safely ignore this email.
BODY
        )
        send!(message)
      end

      private def send!(msg : EMail::Message)
        config = EMail::Client::Config.new(
          CrystalBank::Env.smtp_host,
          CrystalBank::Env.smtp_port,
          helo_domain: CrystalBank::Env.api_domain
        )
        if CrystalBank::Env.smtp_tls
          config.use_tls(EMail::Client::TLSMode::STARTTLS)
        end
        u = CrystalBank::Env.smtp_username
        p = CrystalBank::Env.smtp_password
        config.use_auth(u, p) if u && p
        client = EMail::Client.new(config)
        client.start { |c| c.send(msg) }
      rescue ex
        Log.error { "Mailer error: #{ex.message}" }
      end
    end
  end
end
