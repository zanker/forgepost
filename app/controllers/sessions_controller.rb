class SessionsController < ApplicationController
  before_filter :require_logged_in, :only => :destroy

  def create
    if !CONFIG[:oauth][params[:provider]]
      return redirect_to new_session_path, :alert => t("sessions.create.bad_provider", :provider => params[:provider].to_s)
    elsif !env["omniauth.auth"] or !env["omniauth.auth"].valid?
      return redirect_to new_session_path, :alert => t("sessions.create.bad_login", :email => view_context.mail_to(CONFIG[:contact][:email]))
    end

    omniauth = env["omniauth.auth"]

    remember_token = SecureRandom.base64(60).tr("+/=", "pqr")

    user = User.where(:provider => omniauth.provider, :uid => omniauth.uid.to_s).only(:current_sign_in_ip, :current_sign_in_at, :analytics_id).first
    if user
      user.set(:remember_token => remember_token, :current_sign_in_ip => request.ip, :current_sign_in_at => Time.now.utc, :last_sign_in_at => user.current_sign_in_at)

    # Create a new account for them silently
    else
      new_account = true

      user = User.new
      user.provider = omniauth.provider
      user.uid = omniauth.uid
      user.email = omniauth.info.email
      user.full_name = omniauth.info.name
      user.oauth = {"token" => omniauth.credentials.token, "secret" => omniauth.credentials.secret}
      user.remember_token = remember_token
      user.current_sign_in_ip = request.ip
      user.current_sign_in_at = Time.now.utc

      # Move over the analytics id into the user model too
      if cookies.signed[:aid]
        user.analytics_id = cookies.signed[:aid]
      end

      user.save(:validate => false)
    end

    if cookies[:timezone] and user.timezone == "PST8PDT"
      user.set(:timezone => cookies[:timezone])
    end

    reset_session

    session[:user_id] = user._id.to_s
    cookies.permanent.signed[:provider] = {:value => omniauth.provider, :httponly => true}
    cookies.permanent.signed[:remember_token] = {:value => remember_token, :httponly => true}
    cookies.permanent.signed[:aid] = user.analytics_id

    if new_account
      redirect_to root_path
    elsif env["omniauth.origin"] and env["omniauth.origin"] =~ %r{\A/}
      redirect_to env["omniauth.origin"], :notice => t("sessions.create.logged_in")
    else
      redirect_to root_path, :notice => t("sessions.create.logged_in")
    end
  end

  def destroy
    current_user.unset(:remember_token)
    reset_session

    redirect_to root_path, :notice => t("sessions.destroy.success")
  end

  def failure
    redirect_to new_session_path, :alert => t("sessions.failure.#{params[:message].to_s}", :default => t("sessions.failure.generic", :message => params[:message].humanize))
  end

  def new
  end
end