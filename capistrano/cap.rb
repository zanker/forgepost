Capistrano::Configuration.instance(:must_exist).load do
  before "deploy" do
    logger.info "Pushing git repo for branch #{branch}"
    run_locally(source.scm("push", "origin", branch))

    next if ENV["RSPEC"] == "0"

    logger.info "Running tests"

    results = system("rspec ./")
    unless results
      raise Capistrano::Error.new("Test failure, deploy aborted")
    end
  end

  #before "deploy:finalize_update" do
  #  set :default_shell, "rvm-shell 'jruby-1.7.10'"
  #  run "cd #{latest_release} && bundle install --gemfile #{latest_release}/Gemfile --path /var/www/vhosts/forgepost/shared/bundle --deployment --quiet --without development test"
  #  set :default_shell, "rvm-shell 'ruby-2.1.0'"
  #end
end