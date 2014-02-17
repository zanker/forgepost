class CustomDeck
  include MongoMapper::Document

  key :name, String
  key :card_ids, Array
  key :card_external_ids, Array
  key :quantities, Array
  key :factions, Array

  timestamps!

  belongs_to :user

  validates_length_of :name, :minimum => 1, :maximum => 24
  validates_format_of :name, :without => /\<|\>/

  def deckbuilder_hash
    parts = ["1"]
    self.card_external_ids.each_index do |i|
      parts << Base77.encode("#{self.quantities[i]}#{self.card_external_ids[i]}")
    end

    parts.join(";")
  end
end