class Card
  include MongoMapper::Document

  CATEGORY_MAP = {"creature" => 0, "spell" => 1}
  REVERSE_CATEGORY_MAP = Hash[CATEGORY_MAP.to_a.map {|r| r.reverse}]

  FACTIONS = ["uterra", "nekrium", "alloyin", "tempys"]
  INTERNAL_FACTION_MAP = {"nature" => "uterra", "death" => "nekrium", "mechanical" => "alloyin", "elemental" => "tempys"}
  FACTION_MAP = {"alloyin" => 2, "tempys" => 3, "uterra" => 0, "nekrium" => 1}
  REVERSE_FACTION_MAP = Hash[FACTION_MAP.to_a.map {|r| r.reverse}]

  UNUSED_RARITIES = {1 => true}
  RARITY_MAP = {0 => "common", 1 => "uncommon", 2 => "rare", 3 => "heroic", 4 => "legendary"}
  REVERSE_RARITY_MAP = Hash[RARITY_MAP.to_a.map {|r| r.reverse}]

  RARITY_IMAGE_MAPS = {0 => 1, 2 => 2, 3 => 3, 4 => 4}

  LEVELS = [1, 2, 3]

  key :external_id, Integer

  key :card_id, String

  key :available, Boolean

  key :level, Integer
  key :set_ids, Array
  key :set_external_ids, Array
  key :set_card_ids, Array

  key :name, String
  key :flavor, String

  key :card_set, String

  key :rarity, Integer

  key :faction, Integer

  key :category, Integer

  key :creature_type, String
  key :creature_prim_type, String

  key :token, Boolean, :default => false

  key :attack, Integer
  key :hp, Integer

  key :image_id, String
  key :alt_image_ids, Array, :default => []

  key :abilities, Hash, :default => {}

  key :ability_types, Array, :default => []

  key :static_abilities, Array, :default => []
  key :static_keywords, Array, :default => []
  key :static_text, Array, :default => []

  key :alt_card_ids, Array, :default => []

  key :keywords, Array, :default => []

  key :last_game_version_id, BSON::ObjectId
  key :added_game_version_id, BSON::ObjectId
  key :historic_game_version_ids, Array, :default => []

  timestamps!

  many :internal_abilities, :class_name => "Ability"

  validates_presence_of :name
  validates_presence_of :image_id

  validates_numericality_of :faction
  validates_numericality_of :level
  validates_numericality_of :category
  validates_numericality_of :rarity, :unless => :token?
  validates_numericality_of :attack, :allow_nil => true
  validates_numericality_of :hp, :allow_nil => true


  def border_path(size)
    "borders/#{size}/lvl#{self.level}_#{REVERSE_FACTION_MAP[self.faction]}_#{REVERSE_CATEGORY_MAP[self.category]}.png"
  end

  def token=(token)
    @token = token ? (token.downcase == "true") : false
  end

  def rarity=(rarity)
    @rarity = rarity ? REVERSE_RARITY_MAP[rarity.downcase] : nil
  end

  def faction=(faction)
    @faction = faction ? FACTION_MAP[INTERNAL_FACTION_MAP[faction.downcase]] : nil
  end

  def image_id=(image)
    @image_id = self.class.sanitize_image(image)
  end

  def has_stats?
    self.category == CATEGORY_MAP["creature"]
  end

  def rarity_key
    RARITY_MAP[self.rarity]
  end

  def self.sanitize_image(image)
    Base64.strict_encode64(Digest::MD5.digest(image.parameterize)).tr("+/=", "")
  end
end