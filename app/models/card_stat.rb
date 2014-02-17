class CardStat
  include MongoMapper::Document

  HEALTH, ATTACK = 0, 1
  GLOBAL = -1

  key :count, Integer
  key :avg, Float

  key :creature, String
  key :faction, Integer

  timestamps!
end