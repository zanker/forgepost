class DeckbuildersController < ApplicationController
  before_filter :require_logged_in, :only => [:save_deck, :remove_deck]

  def save_deck
    if params[:id]
      deck = current_user.decks.where(:_id => params[:id].to_s).first
      return render_404 unless deck
    else
      deck = CustomDeck.new(:user_id => current_user._id)
      deck.name = CGI::escapeHTML(params[:name].to_s)
    end

    if params[:cards].is_a?(Hash)
      card_ids = params[:cards].map {|id, total| id.to_i}

      deck.card_external_ids, deck.card_ids, deck.quantities, deck.factions = [], [], [], []
      Card.where(:external_id.in => card_ids).only(:external_id, :faction).each do |card|
        quantity = params[:cards][card.external_id.to_s].to_i
        next if quantity <= 0

        deck.card_ids << card._id
        deck.card_external_ids << card.external_id
        deck.quantities << quantity
        deck.factions << card.faction
      end

      deck.factions.uniq!
    end

    deck.save

    if deck.valid?
      render :nothing => true, :status => :no_content
    else
      render :json => {:msg => deck.errors.full_messages}, :status => :bad_request
    end
  end

  def remove_deck
    deck = current_user.decks.where(:_id => params[:id].to_s).first
    if deck
      deck.destroy
    end

    render :nothing => true, :status => :no_content
  end

  def storage
    @decks = user_signed_in? ? current_user.decks : []

    render :layout => false
  end

  def deck_list
    @decks = user_signed_in? ? current_user.decks : []

    render :layout => false
  end

  def index
    return unless stale?(:public => true, :etag => "#{Rails.cache.read("card-data-cache")}#{cachebust_key}")

    # Load categories
    @categories = {}
    Card::CATEGORY_MAP.each do |key, id|
      @categories[id] = t("categories.#{key}")
    end

    # Creatures
    @creatures = {}
    CreatureType.where(:count.gte => CONFIG[:limits][:keywords]).sort(:text.asc).only(:slug, :text).each do |type|
      @creatures[type.slug] = type.text
    end

    # Keywords
    @keywords = {}
    KeywordInfo.where(:active => true).sort(:external.asc).only(:external, :slug).each do |info|
      @keywords[info.slug] = info.external
    end

    @card_list = {}
  end

  def cards
    last_mod = Rails.cache.read("card-data-cache") || Time.now.utc
    cache_key = "card/tooltips/#{last_mod}"

    expires_in(10.years, :public => true)
    return unless stale?(:public => true, :etag => cache_key, :last_modified => Time.at(last_mod))

    load_tooltip_data

    cards = Card.where(:token => false).sort(:level.asc, :rarity.desc, :faction.desc, :name.asc).map do |card|
      data = {:name => card.name, :level => card.level, :category => card.category, :card_id => card.external_id, :rarity => card.rarity, :faction => card.faction, :set_card_ids => card.set_card_ids, :id => card._id, :keywords => card.keywords}
      data[:url] = cards_url(card.external_id, card.name.parameterize)
      data[:art] = view_context.image_path("cards/small/#{card.image_id}.jpg")
      data[:art_medium] = view_context.image_path("cards/medium/#{card.image_id}.jpg")
      data[:creature] = card.creature_type if card.creature_type?
      data[:creature_prim] = card.creature_prim_type if card.creature_prim_type?

      if card.has_stats?
        data[:atk] = card.attack
        data[:hp] = card.hp
      end

      data[:html] = render_to_string(:partial => "cards/full_card", :locals => {:card => card})
      data
    end

    render :js => "window.card_data = #{cards.to_json}"
  end
end