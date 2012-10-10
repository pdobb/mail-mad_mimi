require "madmimi"

# Temporary Hack? -- For compatibility with the Mail gem: https://github.com/mikel/mail
# Override Hash to respond to 'encoding' or else we get e.g. "NoMethodError Exception: undefined method `encoding' for {:promotion_name=>"test_promotion"}:Hash" when calling .deliver on a mail object with :mad_mimi parameters in it.
class Hash
  def encoding; end
  def encode!(x); x end
end

module Mail #:nodoc:
  # Mail::MadMimi is a delivery method for <tt>Mail</tt>.
  # It uses the <tt>MadMimi</tt> library to send mail via Mad Mimi.

  class MadMimi
    cattr_accessor :api_settings
    attr_accessor :settings, :mimi

    class Error < StandardError; end

    # Add a new attr_accessor on ActionMailer::Base objects for storing the promotion name (which is based on the mailer's action name.)
    if defined? ActionMailer::Base
      ActionMailer::Base.add_delivery_method :mad_mimi, Mail::MadMimi

      module SetMailerAction
        def wrap_delivery_behavior!(*args)
          super
          message.class_eval { attr_accessor :mailer_action }
          message.mailer_action = action_name
        end
      end
      ActionMailer::Base.send :include, SetMailerAction
    end

    # Any settings given here will be passed to Mad Mimi.
    #
    # <tt>:email</tt> and <tt>:api_key</tt> are required.
    def initialize(settings = {})
      self.settings = settings.reverse_merge!(self.class.api_settings)
      unless self.settings[:email] && self.settings[:api_key]
        raise Error, "Missing :email and :api_key settings"
      end
      self.mimi = ::MadMimi.new self.settings[:email], self.settings[:api_key]
    end

    def deliver!(mail)
      recipients = mail[:to].to_s

      recipients.split(",").each do |recipient|
        mail[:to] = recipient
        mad_mimi_body = setup_options_from_mail_and_get_mad_mimi_body(mail)

        mimi.send_mail(self.settings, mad_mimi_body).tap do |response|
          raise Error, response if response.to_i.zero?  # no transaction id
        end
      end
    end


    private

    def setup_options_from_mail_and_get_mad_mimi_body(mail)
      self.settings.merge!(
        :recipients     => mail[:to].to_s,
        :from           => mail[:from].to_s,
        :bcc            => mail[:bcc].to_s,
        :subject        => mail.subject,
        :raw_html       => html(mail),
        :raw_plain_text => text(mail)
      ).reject! { |k,v| v.nil? }

      if mad_mimi_options = mail[:mad_mimi].try(:decoded).try(:clone) # Convert back to a Hash of options via Mail::UnstructuredField#decoded
        # mad_mimi_options is a clone as we will delete :promotion_name from the
        # hash but we may need it again for multiple recipients
        self.settings[:promotion_name] = mad_mimi_options.delete(:promotion_name).presence || (mail.respond_to?(:mailer_action) ? mail.mailer_action : nil)
        return mad_mimi_options
      end
      {}
    end

    def html(mail)
      body(mail, "text/html")
    end

    def text(mail)
      body(mail, "text/plain") || mail.body.to_s
    end

    def body(mail, mime_type)
      if part = mail.find_first_mime_type(mime_type)
        part.body.to_s
      elsif mail.mime_type == mime_type
        mail.body.to_s
      end
    end

  end
end
