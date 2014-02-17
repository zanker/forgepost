class Notification < ActionMailer::Base
  default(:from => "Support <1234>")

  def internal_alert(subject, body)
    mail(:from => "1234", :to => "1234", :subject => subject, :body => body)
  end
end
