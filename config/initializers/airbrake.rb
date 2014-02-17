require "mail"

Airbrake.configure do |config|
  config.secure = false
  config.async do |notice|
    break unless notice.exception

    begin
      body = "Params: #{notice.parameters.inspect}\r\n".force_encoding("UTF-8")
      body << "Session: #{notice.session_data.inspect}\r\n"
      body << "Env: #{notice.cgi_data.inspect}\r\n"
      body << "URL: #{notice.url.force_encoding("UTF-8")}\r\n" if notice.url
      body << "Component: #{notice.controller}\r\n" if notice.controller
      body << "Action: #{notice.action}\r\n" if notice.action
      body << "\r\n"
      body << "#{notice.error_message}\r\n\r\n"
      body << "#{notice.exception.backtrace.join("\r\n")}" if notice.exception.backtrace
      body = body.encode("UTF-8", "UTF-8", :invalid => :replace)

      puts "#{notice.exception.class.name}: #{notice.exception.to_s}"
      puts body.gsub(/\n\n(.+)$/, "").strip

      InternalAlert.deliver(notice.exception.class, "Error #{notice.exception.to_s}", body.strip)

    rescue Exception => ex
      Notification.internal_alert("Error while sending #{ex.message}", "#{ex.class}: #{ex.message}\n\n#{ex.backtrace}").deliver
    end
  end

  if defined?(Forgepost)
    Forgepost::Application.config.filter_parameters.each {|p| config.params_filters << p}
  end
end