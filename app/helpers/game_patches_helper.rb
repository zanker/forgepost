module GamePatchesHelper
  def aggregate_cards(type, version, criteria)
    changes = {}

    last_version = nil
    if type == "changed"
      last_version = GameVersion.where(:_id.ne => version._id, :created_at.lte => version.created_at).sort(:created_at.desc).only(:version).first
      criteria = criteria.where(:historic_game_version_ids => last_version._id) if last_version
    end

    if type != "changed" or last_version
      criteria.where(:token => false, :level => 1).only(:external_id, :name, :rarity, :faction, :set_card_ids, :updated_at).sort(:rarity.desc, :name.asc).each do |card|
        if !last_version
          path = cards_path(card.external_id, card.name.parameterize)
        else
          path = cards_show_old_path(card.external_id, card.name.parameterize, last_version.version.parameterize)
        end

        changes[card.faction] ||= []
        changes[card.faction] << link_to(card.name, path, :class => "card-tt rarity-#{card.rarity}", "data-tooltip" => path_to_asset(cards_tooltip_path(card.set_card_ids[0], Digest::MD5.hexdigest("#{@card_data_cache}#{card.updated_at}")[0, 16])))
      end
    end

    if changes.empty?
      html = content_tag(:div, t(".no_#{type}_cards"), :class => "change-type")
    else
      html = content_tag(:div, t("game_patches.index.#{type}_cards"), :class => "change-type")

      changes.each do |faction, cards|
        list = content_tag(:div, t("factions.#{faction}"), :class => "faction-#{faction} factions")
        list << " " << cards.join(", ").html_safe

        html << content_tag(:div, list, :class => "faction-row")
      end
    end

    html
  end
end