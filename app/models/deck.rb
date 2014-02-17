class Deck
  include MongoMapper::Document

  key :deck_id, String
  key :name, String
  key :desc, String

  key :category, String
  key :set_type, String

  key :card_ids, Array
  key :card_external_ids, Array
  key :quantities, Array

  key :factions, Array

  belongs_to :product

  def deckbuilder_hash
    parts = ["1"]
    self.card_external_ids.each_index do |i|
      parts << Base77.encode("#{self.quantities[i]}#{self.card_external_ids[i]}")
    end

    parts.join(";")
  end
end