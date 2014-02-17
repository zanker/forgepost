#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

["1.0.0", "1.5.0", "2.0.0", "2.1.0"].each do |version_id|
  version = GameVersion.where(:version => version_id).first

  root = Rails.root.join("data", "SolForge #{version_id}", "Payload", "solforge.app", "data", "released")

  CardHistory.where(:game_version_id => version._id).delete_all

  ["MVP1", "Release2"].each do |type|
    next unless File.exists?("#{root}/Cards_#{type}_Cards.json")
    cards = JSON.parse(File.read("#{root}/Cards_#{type}_Cards.json"))

    cards["cards"].each do |data|
      data["Rarity"] = "Heroic" if data["Rarity"] == "Epic"
      data["Rarity"] = "Rare" if data["Rarity"] == "Uncommon"

      clone_history = CardHistory.where(:card_id => data["CardID"]).sort(:game_version_id.asc).first
      if data["CardName"] == "Spirit Warrior"
        clone_history = CardHistory.where(:name => data["CardName"], :level => data["Level"].to_i).sort(:game_version_id.asc).first
      end

      unless clone_history
        puts "Cannot find #{data.inspect}, #{version.inspect}"
        next
      end

      attribs = clone_history.attributes
      attribs.delete("_id")
      attribs["created_at"] = version.created_at
      attribs["updated_at"] = version.created_at
      attribs["game_version_id"] = version._id
      attribs["rarity"] = Card::REVERSE_RARITY_MAP[data["Rarity"].downcase] if data["Rarity"]
      attribs["creature_type"] = data["CreatureType"]
      attribs["abilities"] = {}
      attribs["hp"] = data["Health"].to_i
      attribs["attack"] = data["Power"].to_i
      attribs["image_id"] = Card.sanitize_image(data["Art"])
      attribs["name"] = data["CardName"].strip

      if data["CardText"]
        text = data["CardText"].strip
        if data["Keywords"]
          data["Keywords"].split(",").each do |keyword|
            keyword.strip!
            text = text.gsub(/#{keyword}\s{1,}\(.+?\)[\.]?/, "")
          end

          data["Keywords"].split(",").each do |keyword|
            keyword.strip!
            text = text.gsub(/#{keyword}/, "")
          end
        end

        text.strip!
        text = "" if text == "."

        attribs["static_abilities"] = text.blank? ? [] : [text]
      else
        attribs["static_abilities"] = []
      end

      attribs["keywords"] = []
      attribs["static_keywords"] = []

      if data["Keywords"]
        keywords = data["Keywords"].gsub("Fast", "Aggressive").gsub("Move", "Mobility").split(",")
        keywords.each do |keyword|
          keyword.strip!

          type = keyword.split(" ", 2).first

          attribs["keywords"] << type
          attribs["static_keywords"] << keyword
        end

        attribs["keywords"].uniq!
      end

      CardHistory.create!(attribs)
    end
  end

  CardHistory.where(:game_version_id => version._id).each do |history|
    history.set(:set_card_ids => CardHistory.where(:game_version_id => version._id, :external_id => history.set_external_ids).sort(:level.asc).map {|h| h._id})
  end
end

SyncCardHistory.new.perform
Rails.cache.clear

["deck", "card", "product"].each do |type|
  Rails.cache.write("#{type}-cache", Time.now.utc.to_i)
  Rails.cache.write("#{type}-data-cache", Time.now.utc.to_i)
end
