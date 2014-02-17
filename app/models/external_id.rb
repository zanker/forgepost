class ExternalId
  include MongoMapper::Document

  CARD = 0

  key :type, Integer
  key :count, Integer

  def self.generate_id(type)
    res = self.where(:type => type).find_and_modify(:update => {"$inc" => {:count => 1}}, :upsert => true, :new => true)
    res["count"]
  end
end