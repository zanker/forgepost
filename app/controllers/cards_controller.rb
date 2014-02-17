class CardsController < ApplicationController
  helper_method :card_tooltip_data

  STAT_FILTERS = {"hp" => :hp, "atk" => :attack}
  SORT_KEYS = {"name" => [:name, :rarity], "rarity" => [:rarity, :name], "type" => [:category], "faction" => [:faction, :rarity], "attack" => [:attack, :category, :rarity], "hp" => [:hp, :category, :rarity], "creature" => [:creature_type], "updated-version" => [:last_game_version_id], "abilities" => [:static_abilities]}

  def tooltip
    cards = Card.where(:set_card_ids => BSON::ObjectId(params[:card_id].to_s)).sort(:level.asc)
    return render_404 unless cards.exists?

    return unless stale?(:public => true, :etag => cards.map {|c| c.cache_key}.join, :last_modified => cards.map {|c| c.updated_at}.max)

    load_tooltip_data

    render "full_card_set", :locals => {:cards => cards}, :layout => false
  end

  def ext_tooltip
    levels = params[:level].split(",").map {|l| l.to_i}

    cards = Card.where(:set_external_ids => params[:card_id].to_i, :level.in => levels).sort(:level.asc).map {|c| c}
    return render :nothing => true, :status => :not_found if cards.empty?
    return unless stale?(:public => true, :etag => cards.map {|c| c.cache_key}.join, :last_modified => cards.map {|c| c.updated_at}.max)

    load_tooltip_data

    if cards.length == 1
      body = render_to_string :partial => "full_card", :locals => {:card => cards[0]}, :layout => false
    else
      body = render_to_string "full_card_set", :locals => {:cards => cards}, :layout => false
    end

    render :js => "$ForgePost.tooltip_loaded(#{params[:card_id]},\"#{CGI::escape(body)}\")"
  end

  def show_old
    show
  end

  def show_alt
    @alt = true
    show

    return unless self.response_body.blank?
    return render "show"
  end

  def show
    load_card_data
    return unless @card

    # Use an old version
    if params[:version]
      version_id = GameVersion.version_to_id(params[:version].gsub("-", "."))
      return render_404 if version_id.blank?

      @card_data = CardHistory.where(:live_card_id => @card._id, :game_version_id => version_id).sort(:created_desc).first
      return render_404 unless @card_data

      @live_card = @card
      @card = @card_data

      @game_version = params[:version].gsub("-", ".")

    # Use the live data
    else
      @card_data = @card
      @live_card = @card
    end

    # No alt versions found
    if @alt and !@card.alt_image_ids?
      return render_404
    end

    # Grab all 3 versions
    @card_levels = [@card]
    (params[:version] ? CardHistory : Card).where(:_id.ne => @card._id, :set_card_ids.in => [@card._id]).each do |card|
      @card_levels << card
    end

    @card_levels.sort_by! {|c| c.level}

    if @game_version
      @next_version_id = GameVersion.next_version_id(version_id)
      @active_version_id = GameVersion.active_version_id

      @next_card_levels = []

      # Comparing vs live
      if @next_version_id == @active_version_id
        @next_card_levels << @live_card

        Card.where(:_id.ne => @live_card._id, :set_card_ids.in => [@live_card._id]).each do |card|
          @next_card_levels << card
        end

      # Comparing vs next version
      else
        CardHistory.where(:game_version_id => @next_version_id, :live_card_id.in => @live_card.set_card_ids).each do |card|
          @next_card_levels << card
        end
      end

      @next_card_levels.sort_by! {|c| c.level}
    end

    # And grab its history
    @history = Rails.cache.fetch("card-history/#{@live_card.set_external_ids}/#{GameVersion.active_version_id}", :expires_in => 1.week) do
      card_ids = @card_levels.map {|c| @game_version ? c.live_card_id : c._id}

      changes = {}
      CardHistory.where(:live_card_id.in => card_ids, :total_changes.gt => 0).only(:total_changes, :game_version_id, :created_at).sort(:created_at.desc).each do |history|
        changes[history.game_version_id] = {:total_changes => history.total_changes, :game_version_id => history.game_version_id, :created_at => history.created_at}
      end

      rows = []
      GameVersion.where(:_id.in => changes.keys).sort(:build.desc).each do |version|
        rows << changes.delete(version._id).merge(:game_version => version.version)
      end

      rows
    end

    load_tooltip_data

    # Load stats
    @card_stats = {}

    if !@game_version && @card.has_stats?
      criteria = []
      @card_levels.each do |card|
        criteria << {:level => card.level, :faction => card.faction}
        criteria << {:level => card.level, :faction => CardStat::GLOBAL}

        if card.creature_prim_type?
          criteria << {:level => card.level, :creature => card.creature_prim_type}
        end
      end

      CardStat.where("$or" => criteria).each do |stat|
        @card_stats[stat.level] ||= {}

        if stat.creature?
          data = @card_stats[stat.level][:creature] ||= {}
        elsif stat.faction == CardStat::GLOBAL
          data = @card_stats[stat.level][:global] ||= {}
        else
          data = @card_stats[stat.level][:faction] ||= {}
        end

        data[stat.type == CardStat::HEALTH ? :hp : :attack] = {:total => stat.count, :avg => stat.avg}
      end
    end
  end

  def index
    @card_data_cache = Rails.cache.read("card-data-cache")
    return unless stale?(:public => true, :etag => "#{request.path}#{@card_data_cache}#{cachebust_key}")

    @filters = {:factions => {}, :rarities => {}}

    @cards = Card.where.limit(CONFIG[:limits][:cards])
    if SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
      @cards = @cards.sort(*(SORT_KEYS[params[:sort_by]].map {|key| key.send(params[:sort_mode])} << :level.asc))

    else
      @cards = @cards.sort(:rarity.desc, :name.asc, :level.asc)
      params[:sort_by], params[:sort_mode] = "rarity", "desc"
    end

    # Factions
    if params[:factions] != "all"
      params[:factions].split("-").each do |faction|
        if Card::FACTION_MAP[faction]
          @filters[:factions][Card::FACTION_MAP[faction]] = true
        end
      end

      unless @filters[:factions].empty?
        @cards = @cards.where(:faction.in => @filters[:factions].keys)
      end
    else
      Card::FACTION_MAP.each_value {|k| @filters[:factions][k] = true}
    end

    # Rarities
    if params[:rarities] != "all"
      params[:rarities].split("-").each do |rarity|
        if Card::REVERSE_RARITY_MAP[rarity]
          @filters[:rarities][Card::REVERSE_RARITY_MAP[rarity]] = true
        end
      end

      unless @filters[:rarities].empty?
        @cards = @cards.where(:rarity.in => @filters[:rarities].keys)
      end
    else
      Card::RARITY_MAP.each_key {|k| @filters[:rarities][k] = true}
    end

    # Stats
    STAT_FILTERS.each do |key, field|
      unless params["min_#{key}"].blank?
        @cards = @cards.where(field => {"$gte" => params["min_#{key}"].to_i})
      end

      unless params["max_#{key}"].blank?
        @cards = @cards.where(field => {"$lte" => params["max_#{key}"].to_i})
      end
    end

    # Load categories and shit
    @categories = {}
    Card::CATEGORY_MAP.each do |key, id|
      @categories[key] = {:name => t("categories.#{key}"), :slug => t("categories.#{key}").parameterize}

      if params[:category] == @categories[key][:slug]
        @filters[:category] = key
        @cards = @cards.where(:category => id)
      end
    end

    # Creatures
    @creatures = {}
    CreatureType.where(:count.gte => CONFIG[:limits][:keywords]).sort(:text.asc).only(:slug, :text).each do |type|
      @creatures[type.slug] = type.text

      if params[:creature_type] == type.slug
        @filters[:creature] = type.slug
        @cards = @cards.where(:creature_prim_type => type.text)
      end
    end

    # Keyword Info
    @keyword_info = {}
    KeywordInfo.where(:active => true).sort(:external.asc).only(:external, :slug).each do |info|
      @keyword_info[info.slug] = info.external

      if params[:keywords] == info.slug
        @filters[:keyword] = info.slug
        @cards = @cards.where(:keywords => info.external)
      end
    end

    # Level
    if params[:level] != "all"
      @cards = @cards.where(:level => params[:level].to_i)
      @filters[:level] = params[:level].to_i
    end

    # Sets
    if params[:set] != "all"
      @filters[:set] = "set#{params[:set].gsub("-", ".")}"
      @cards = @cards.where(:card_set => @filters[:set])
    end

    # Pagination
    if params[:page].to_i > 0
      @cards = @cards.skip((params[:page].to_i - 1) * CONFIG[:limits][:cards])
    end

    load_tooltip_data
  end

  private
  def load_card_data
    @card = Card.where(:external_id => params[:card_id].to_i).first
    unless @card
      return render_404
    end

    return unless stale?(:etag => "#{@card.cache_key}#{params[:action]}/#{params[:version]}#{cachebust_key}")
  end
end