class CreatureType
  include MongoMapper::Document

  key :slug, String
  key :text, String

  key :count, Integer

  timestamps!
end