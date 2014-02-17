class AbilityTest
  include MongoMapper::Document

  key :test, String
  key :target, String
  key :operator, String
  key :value, String
  key :param, String

  key :require_all, Boolean
  key :stable_board, Boolean

  belongs_to :keyword_info

  timestamps!
end