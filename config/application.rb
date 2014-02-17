require File.expand_path("../boot", __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => ["development", "test"]))
end

module Forgepost
  class Application < Rails::Application
    Dir[Rails.root.join("lib", "**", "*.rb")].each {|f| require f}

    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
    config.autoload_paths += [config.root.join("lib")]
    config.filter_parameters += [:password, :password_confirmation]

    config.assets.logger = false

    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    config.assets.precompile << "usercp.js"
    config.assets.precompile << "usercp.css"
    config.assets.precompile << "server_error.css"
    config.assets.precompile << "timezone.js"
    config.assets.precompile << ".ttf"
    config.assets.precompile << "icon-128.png"
    config.assets.precompile << "apple-touch-icon.png"
    config.assets.precompile << "tooltips.js"
    config.assets.precompile << "tooltips.css"

    config.exceptions_app = self.routes

    if config.respond_to?(:less)
      config.less.paths << Rails.root.join("app", "assets", "stylesheets", "bootstrap")
    end

    if defined?(Compass)
      Compass.configuration.generated_images_path = "#{config.root}/public/assets/"
      Compass.configuration.generated_images_dir = "public/assets/"
    end

    Haml::Template.options[:format] = :html5

    config.encoding = "utf-8"

    config.after_initialize do
      unless Rails.env.test?
        ActionMailer::Base.default_url_options[:host] = CONFIG[:domain]
        ActionController::Base.default_url_options[:host] = CONFIG[:domain].split(":", 2)[0]
      end
    end
  end
end
