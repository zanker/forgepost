Forgepost::Application.configure do
  config.action_controller.asset_host = "http://localhost:3000"

  config.dev_tweaks.log_autoload_notice = false
  config.dev_tweaks.autoload_rules do
    keep :xhr
  end

  config.assets.compress = false
  config.assets.debug = true

  config.cache_classes = false

  config.whiny_nils = true

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  config.action_mailer.raise_delivery_errors = false

  config.active_support.deprecation = :log

  config.action_dispatch.best_standards_support = :builtin

  config.cache_store = :null_store

  DEPLOY_ID = ""
end