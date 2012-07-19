# Mail::MadMimi

`Mail::MadMimi` is a delivery method for `Mail`.
It uses the `MadMimi` library to send mail via [Mad Mimi][1].

## Installation

Add to your `Gemfile`:

    gem 'mail-mad_mimi', :require => 'mail/mad_mimi', :git => 'git://github.com/pdobb/mail-mad_mimi.git'

## About this fork

Updated Mail::MadMimi to work with Rails 3.2.6 and fleshed out the system for passing MadMimi placeholders in with the standard ActionMailer style. I tried to stick to the original author's original intent so most of this documentation still makes sense. I added my own usage scenario, though (see "Documentation for this fork," below).

## Usage

### Original Documentation:

    require "mail"
    require "mail/mad_mimi"

    mail = Mail.new do
      to              "user@example.com"
      from            "sender@example.com"
      subject         "test"
      delivery_method Mail::MadMimi, :email => "sender@example.com", :api_key => "1234"
    end

    mail.deliver

### Documentation for this fork (assumes the presence of at least Rails 3.2.6 on Ruby 1.9.3):

config/initializers/mail_mad_mimi.rb

    Mail::MadMimi.api_settings = {
      :email   => <your MadMimi account email/login>,
      :api_key => <your MadMimi account API Key>
    }

app/mailers/user_mailer.rb

    class UserMailer < ActionMailer::Base
      self.delivery_method = :mad_mimi

      default from: "Your Name <Your Email Address>", return_path: "Your Name <Your Email Address>"

      def test_promotion
        user = User.first
        mad_mimi_options = {firstName: user.first_name, lastName: user.last_name}
        mad_mimi_options.merge(promotion_name: 'test_promotion') # Optional (only needed if different than the current action name).
        mail(subject: "Test", to: user.email, mad_mimi: mad_mimi_options)
      end
    end

On the console or in a controller, etc.

    UserMailer.test_promotion.deliver


## Headers and options

The `:to`, `:from`, `:bcc`, and `:subject`
headers are taken from the `Mail` object passed to
`deliver`

In addition, any hash values given as a `:mad_mimi` header are
passed on to Mad Mimi. That means if you use the `Mail` object with
a different delivery method, you'll get an ugly `mad_mimi` header.

You can see other available options on the [Mad Mimi developer site][2].

HTML (`:raw_html`) and plain text (`:raw_plain_text`) bodies are extracted
from the `Mail` object.

Use `:list_name => "beta users"` to send to a list or `:to_all => true`
to send to all subscribers.

## Mad Mimi macros

If you are sending to an individual email address, the body must
include `[[tracking_beacon]]` or `[[peek_image]]`.

If you are sending to a list or everyone, the body must include
`[[opt_out]]` or `[[unsubscribe]]`.

An exception will be raised if you don't include a macro. When debugging,
you may want to set `raise_delivery_errors = true` on your `Mail` object.

## Rails 3 support

If `ActionMailer` is loaded, `Mail::MadMimi` registers itself as a
delivery method.

You can then configure it in an environment file:

    config.action_mailer.delivery_method = :mad_mimi
    config.action_mailer.mad_mimi_settings = {
      :email   => "user@example.com",
      :api_key => "a1b9892611956aa13a5ab9ccf01f4966",
    }

If only some of your Mailers should use the `:mad_mimi` delivery_method, this fork allows you to specify the default mad_mimi_settings in a config/initializer file. See "Documentation for this fork," above for an example.

[1]: http://madmimi.com
[2]: http://madmimi.com/developer/mailer/transactional
