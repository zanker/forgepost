class Price
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::SkipIdField

  key :sku, String
  key :quantity, Integer
  key :cost, Integer

  embedded_in :product

  def gold?
    self.sku == "general.currency.gold"
  end

  def silver?
    self.sku == "general.currency.silver"
  end
end