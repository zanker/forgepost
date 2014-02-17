class ReferencesController < ApplicationController
  before_filter do
    @card_data_cache = Rails.cache.read("card-data-cache")
    return unless stale?(:public => true, :etag => "#{@card_data_cache}#{params[:controller]}#{params[:action]}#{params[:faction]}#{cachebust_key}")
  end

  caches_action :faction, :keywords, :mechanics, :rarities, :cache_path => proc { "#{params[:controller]}-#{params[:action]}-#{params[:faction]}-#{@card_data_cache}-#{cachebust_key}"}, :expires_in => 24.hours

  def faction
    unless Card::FACTION_MAP[params[:faction]]
      return render_404
    end

    @faction = Faction.where(:faction => params[:faction].to_s).first
  end

  def keywords
  end

  def mechanics
    @references = {}

    [["draw1", Card.where(:keywords => "Card Draw")], ["agg1", Card.where(:keywords => "Aggressive", :category => Card::CATEGORY_MAP["creature"])], ["agg2", Card.where(:keywords => "Aggressive", :category => Card::CATEGORY_MAP["spell"])]].each do |type, criteria|
      card = criteria.only(:level, :faction, :set_card_ids, :external_id, :name, :updated_at).first
      @references[type] = view_context.link_to(card.name, cards_path(card.external_id, card.name.parameterize), :class => "faction-#{card.faction} card-tt", "data-tooltip" => view_context.path_to_asset(cards_tooltip_path(card.set_card_ids[0], Digest::MD5.hexdigest("#{@card_data_cache}#{card.updated_at}")[0, 16])))
    end

    ["aggressive"].each do |keyword|
      keyword = KeywordInfo.where(:slug => keyword).first

      html = ""
      html << view_context.image_tag("status/tiny/#{keyword.slug}.png", :height => 19, :width => 20)
      html << view_context.link_to(keyword.external, cards_index_search_path(:keywords => keyword.slug, :level => :all), :class => "alt tt", :title => keyword.desc)
      @references[keyword.slug] = html
    end
  end
end