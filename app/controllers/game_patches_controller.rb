class GamePatchesController < ApplicationController
  caches_action :index, :show, :cache_path => proc { "#{params[:controller]}-#{params[:action]}-#{params[:page]}-#{params[:version]}-#{DEPLOY_ID}"}, :expires_in => 24.hours

  def show
    @card_data_cache = Rails.cache.read("card-data-cache")

    @criteria = [GameVersion.where(:_id => GameVersion.version_to_id(params[:version].tr("-", "."))).first]
    if @criteria.empty?
      return render_404
    end

    render :index
  end

  def index
    @card_data_cache = Rails.cache.read("card-data-cache")

    @criteria = GameVersion.sort(:created_at.desc).limit(CONFIG[:limits][:news])
    if params[:page].to_i > 0
      @criteria = @criteria.skip((params[:page].to_i - 1) * CONFIG[:limits][:news])
    end

    unless @criteria.exists?
      return render_404
    end
  end
end