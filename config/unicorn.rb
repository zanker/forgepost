worker_processes 15
working_directory "/var/www/vhosts/forgepost/current"

listen "0.0.0.0:8200"

preload_app true

user "unicorn", "cap-deploy"

pid "/var/run/unicorn/forgepost.pid"

stderr_path "/var/log/unicorn/forgepost.err.log"
stdout_path "/var/log/unicorn/forgepost.out.log"

before_fork do |server, worker|
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
     begin
       sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
       Process.kill(sig, File.read(old_pid).to_i)
     rescue Errno::ENOENT, Errno::ESRCH
     end
  end

  ActiveRecord::Base.connection.close if defined?(ActiveRecord::Base)
  MongoMapper.database.connection.close
  Redis.current.with {|r| r.client.disconnect}
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
  MongoMapper.database.connection.connect
  Redis.current.with {|r| r.client.reconnect}
end

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{Unicorn::HttpServer::START_CTX[:cwd]}/Gemfile"
end