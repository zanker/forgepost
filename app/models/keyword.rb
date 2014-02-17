class Keyword
  include MongoMapper::Document

  key :type, String
  key :desc, String
  key :base, String

  key :generic, Boolean

  timestamps!
end