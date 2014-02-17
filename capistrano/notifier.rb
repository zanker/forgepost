Capistrano::Configuration.instance(:must_exist).load do
  after "deploy:update" do
    # Push to Airbrake
    #require "airbrake"
    #require "airbrake_tasks"
    #require "config/initializers/airbrake"
    #
    #AirbrakeTasks.deploy(:rails_env => fetch(:rails_env, "production"), :scm_revision => current_revision, :local_username => ENV["USER"])

    # Push to Librato
    require "net/http"
    require "json"
    require "base64"
    annotation = {"title" => "Deployed #{current_revision[0, 12]}", "description" => "#{ENV["USER"]} deployed #{current_revision}", "source" => ENV["USER"]}

    http = Net::HTTP.new("metrics-api.librato.com", 443)
    http.use_ssl = true
    http.request_post("/v1/annotations/deploy.forgepost", annotation.to_json, {"Content-Type" => "application/json", "Authorization" => "Basic #{Base64.strict_encode64("1234:1234")}"})
  end
end