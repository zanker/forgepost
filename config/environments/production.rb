Forgepost::Application.configure do
  Haml::Template.options[:ugly] = true

  #config.static_cache_control = "public, max-age=3600"

  config.action_controller.page_cache_directory = "public/cache"

  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  config.assets.js_compressor = :uglifier

  config.cache_classes = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.serve_static_assets = false

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"

  config.cache_store = :dalli_store, "127.0.0.1:11211", {:value_max_bytes => 4.megabytes}

  DEPLOY_ID = Digest::SHA1.hexdigest("#{Time.now.to_f}")

  #WEBP_ASSETS = {}
  #
  #base = Rails.root.join("public", "assets").to_s << "/"
  #
  #Dir[Rails.root.join("public", "assets", "**", "*.webp")].each do |path|
  #  path.gsub!(base, "")
  #  WEBP_ASSETS[path.gsub(/webp$/, "png")] = path
  #end
end