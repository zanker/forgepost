class CardHistory < Card
  set_collection_name "card_histories"

  key :total_changes, Integer
  key :fields_changed, Array, :default => []

  belongs_to :game_version
  belongs_to :live_card, :class_name => "Card"

  def rarity=(val); @rarity = val end
  def token=(val); @token = val end
  def faction=(val); @faction = val end
  def image_id=(val); @image_id = val end
end