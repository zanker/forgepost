# Fix it so we can use /sessions/google/callback and such
class OmniAuth::Strategies::GoogleOauth2 < OmniAuth::Strategies::OAuth2
  option :name, 'google'
end

Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "/sessions"
    config.full_host = CONFIG[:full_domain]
  end

  provider :developer unless Rails.env.production?
  provider :google_oauth2, CONFIG[:oauth][:google][:key], CONFIG[:oauth][:google][:secret], :approval_prompt => "auto", :access_type => "online"
  provider :facebook, CONFIG[:oauth][:facebook][:key], CONFIG[:oauth][:facebook][:secret], :scope => "email"
end