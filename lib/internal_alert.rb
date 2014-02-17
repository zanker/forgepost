class InternalAlert
  def self.deliver(klass, subject, body="")
    if Rails.env.development? or Rails.env.test?
      puts "#{klass}: #{subject}"
      puts body
      return
    end

    id = Digest::MD5.hexdigest("#{klass}#{subject}#{DEPLOY_ID}")

    Redis.current.with do |r|
      res = r.setnx("alerts-#{id}", "1")
      # Already set
      return unless res
      r.expire("alerts-#{id}", 5.minutes)
    end

    Notification.internal_alert("[#{klass.name}] #{subject}", body).deliver

  rescue Exception => ex
    Notification.internal_alert("Error while sending #{ex.message}", "#{ex.class}: #{ex.message}\n\n#{ex.backtrace}").deliver
  end
end