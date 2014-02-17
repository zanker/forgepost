class SyncCardHistory
  include Sidekiq::Worker
  sidekiq_options :queue => :medium, :retry => false

  CHANGED_FIELDS = [:attack, :hp, :name, :image_id, :creature_type, :rarity, :faction, :flavor, :category, :ability_types, :static_abilities, :level]

  def perform
    # First go through each version, and resync the set ids
    @first_version = GameVersion.sort(:build.asc).first
    @last_version = GameVersion.sort(:build.desc).first

    GameVersion.sort(:build.asc).each do |version|
      next if version == @last_version
      self.update_history(version)
    end

    Card.each do |card|
      version_ids = []
      added_version_id = nil
      CardHistory.where(:live_card_id.in => card.set_card_ids).sort(:game_version_id.asc).only(:game_version_id, :total_changes).each do |history|
        added_version_id ||= history.game_version_id
        version_ids << history.game_version_id if history.total_changes > 0
      end

      card.set(:historic_game_version_ids => version_ids, :last_game_version_id => version_ids.last, :added_game_version_id => added_version_id)
    end
  end

  def update_history(version)
    next_version = GameVersion.where(:_id.gt => version._id).sort(:_id.desc).first

    # Grab the "latest" cards according to history
    db_cards = {}

    if next_version == @last_version
      Card.each do |card|
        db_cards[card.external_id] = card
      end
    else
      CardHistory.where(:game_version_id => next_version._id).each do |card|
        db_cards[card.external_id] = card
      end
    end

    return if db_cards.empty?

    # Grab this versions of cards
    db_history, card_id_map = {}, {}
    CardHistory.where(:game_version_id => version._id).each do |history|
      db_history[history._id] = history
      card_id_map[history.live_card_id] = history._id
    end

    db_history.each_value do |history|
      card = db_cards[history.external_id]

      # Update the card set ids
      set_card_ids = history.set_card_ids.map {|id| card_id_map[id] || id}

      # Figure out # of changes
      fields = []
      CHANGED_FIELDS.each do |field|
        unless card.send(field) == history.send(field)
          fields << field.to_s
        end
      end

      if history.total_changes != fields.length || history.set_card_ids != set_card_ids
        history.set(:updated_at => Time.now.utc)
      end

      history.set(:total_changes => fields.length, :set_card_ids => set_card_ids, :fields_changed => fields)
    end
  end
end
