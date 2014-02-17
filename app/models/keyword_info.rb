class KeywordInfo
  include MongoMapper::Document

  key :internal, String
  key :external, String
  key :desc, String

  key :active, Boolean

  key :count, Integer
  key :faction_count, Hash

  timestamps!
end