class ApplicationController < ActionController::Base
  before_filter do
    Thread.current[:use_webp] = (request.user_agent =~ /(Android\s|Chrome\/|Opera9.8*Version\/..\.|Opera..\.)/) ? true : false
  end

  before_filter :authenticate_user
  after_filter { StatTracker.batch.flush }

  protect_from_forgery
  helper_method :current_user, :user_signed_in?, :analytics_id

  if Rails.env.production?
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from ActionController::MethodNotAllowed, :with => :render_home
    rescue_from Exception, :with => :handle_exception
  end

  def render_404
    return render "errors/404", :formats => [:html], :status => 404
  end

  protected
  def cachebust_key
    "#{cookies[:nt]}#{Post.last_post}#{user_signed_in?}#{DEPLOY_ID}"
  end

  def load_tooltip_data
    return if @tooltip_data

    @tooltip_data = Rails.cache.fetch("tooltip-data/#{DEPLOY_ID}/#{@card_data_cache || Rails.cache.read("card-data-cache")}", :expires_in => 24.hours) do
      data = {"keywords" => {}, "help" => {}}

      # Keywords
      Keyword.where(:base.exists => true).sort(:type.desc).only(:type, :base, :desc).each do |row|
        data["keywords"][row.type] = [row.base.parameterize, row.desc]
      end

      # Help text
      HelpText.only(:text, :desc).each do |row|
        data["help"][row.text] = row.desc
      end

      data
    end
  end

  def cache_page_by_hash(cache_tag, expiration=30.minutes)
    unless config.perform_caching
      yield if block_given?
      return
    end

    cache_tag = Digest::MD5.hexdigest("#{cache_tag}#{cachebust_key}")
    return unless stale?(:etag => cache_tag, :public => true)

    # Don't cache for bots
    if request.user_agent =~ /https?:\/\//i
      return yield if block_given?
    end

    body = Rails.cache.read("page/#{cache_tag}")
    unless body
      yield if block_given?

      body = self.render_to_string
      Rails.cache.write("page/#{cache_tag}", body, :expires_in => expiration, :raw => true)
    end

    self.response_body = body
  end

  def analytics_id
    if @current_user
      @current_user.analytics_id
    else
      unless cookies.signed[:aid]
        cookies.permanent.signed[:aid] = SecureRandom.hex(12)
      end

      cookies.signed[:aid]
    end
  end

  def require_logged_in
    unless @current_user
      return redirect_to new_session_path, :alert => t("page_errors.must_login")
    end
  end

  def require_logged_out
    if @current_user
      return redirect_to usercp_cards_path, :alert => t("page_errors.logged_in")
    end
  end

  def authenticate_user
    if session[:user_id] and cookies.signed[:remember_token]
      @current_user = User.where(:_id => session[:user_id].to_s, :remember_token => cookies.signed[:remember_token].to_s).first
    elsif cookies.signed[:remember_token]
      @current_user = User.where(:remember_token => cookies.signed[:remember_token].to_s).first
      # Restart the session
      session[:user_id] = @current_user._id if @current_user
    end

    # Keep track of logins
    if @current_user and ( !@current_user.current_sign_in_at? or @current_user.current_sign_in_at <= 1.hour.ago.utc )
      @current_user.set(:current_sign_in_at => Time.now.utc, :last_sign_in_at => @current_user.current_sign_in_at, :current_sign_in_ip => request.ip)
    end
  end

  def user_signed_in?; !!@current_user end
  def current_user; @current_user end

  def respond_with_model(model, status=:ok)
     if model.errors.empty?
       render :json => {:id => model._id}, :status => status
     else
       data = {:errors => {}.merge(model.errors.messages), :attributes => {}, :scope => model.class.collection_name.singularize}
       data[:errors].each_key {|e| data[:attributes][e] = model.class.human_attribute_name(e)}

       # Check for children
       data[:errors].merge!(load_model_errors(model, data[:attributes]))

       render :json => data, :status => :bad_request
     end
  end

  def load_model_errors(model, attrib_scope)
    errors = {}

    model.associations.each do |key, assoc|
      next unless assoc.embeddable? and model.errors[key]
      embedded = model.send(key)
      next unless embedded

      errors[key] = {}

      # Multiple embedded
      if assoc.is_a?(MongoMapper::Plugins::Associations::ManyAssociation)
        embedded.each do |child|
          next if child.errors.empty?

          errors[key][child._id] = {}.merge(child.errors.messages)
          errors[key][child._id].each_value {|v| v.uniq!}
          errors[key][child._id].each_key {|e| attrib_scope[e] = assoc.klass.human_attribute_name(e)}
          errors[key][child._id].merge!(load_model_errors(child, attrib_scope))
        end

      # Single embedded, merge any errors
      else
        errors[key].merge!(embedded.errors.messages)
        errors[key].each_value {|v| v.uniq!}
        errors[key].each_key {|e| attrib_scope[e] = assoc.klass.human_attribute_name(e)}

        errors[key].merge!(load_model_errors(embedded, attrib_scope))
      end

      if errors[key].empty?
        errors.delete(key)
        next
      end
    end

    errors
  end


  private
  def handle_exception(exception)
    Airbrake.notify(exception, airbrake_request_data)
    return render "public/500", :formats => [:html], :status => 500, :layout => false
  end
end
