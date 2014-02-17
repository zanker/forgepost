class Faction
  include MongoMapper::Document

  key :faction, String
  key :faction_id, Integer

  key :count, Integer
  key :rarity_count, Hash, :default => {}
end