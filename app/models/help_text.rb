class HelpText
  include MongoMapper::Document

  key :text, String
  key :desc, String

  timestamps!
end