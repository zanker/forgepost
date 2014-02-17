class Product
  include MongoMapper::Document

  GOLD, SILVER, BOOSTER, DECK, SKIN, ITEM = 0, 1, 2, 3, 4, 5
  COW, COD = 6, 7

  key :category, Integer
  key :cat_desc, String

  key :sku, String

  key :title, String
  key :desc, String

  key :max_quantity, Integer

  key :factions, Array

  many :prices
  many :contents

  timestamps!
end