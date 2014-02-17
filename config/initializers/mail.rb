if Rails.env.production?
  auth = {
    :address => "smtp.mandrillapp.com",
    :port => 25,
    :enable_starttls_auto => true,
    :user_name => "1234",
    :password  => "1234",
    :authentication => "login",
    :domain => "1234",
  }

  ActionMailer::Base.add_delivery_method :smtp, Mail::SMTP, auth

  ActionMailer::Base.delivery_method = :smtp

  Mail.defaults do
    delivery_method :smtp
  end

else
  ActionMailer::Base.delivery_method = :test

  Mail.defaults do
    delivery_method :test
  end
end