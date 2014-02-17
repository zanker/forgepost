class Content
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::SkipIdField

  key :sku, String
  key :quantity, Integer

  embedded_in :product
end