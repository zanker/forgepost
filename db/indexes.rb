# Card
Card.create_index([[:card_id, Mongo::ASCENDING]], :unique => true)
Card.create_index([[:external_id, Mongo::ASCENDING]], :unique => true)

# CardHistory
CardHistory.create_index([[:card_id, Mongo::ASCENDING]])
CardHistory.create_index([[:external_id, Mongo::ASCENDING]])
CardHistory.create_index([[:live_card_id, Mongo::ASCENDING]])
CardHistory.create_index([[:game_version_id, Mongo::ASCENDING]])

# Card & CardHistory
[Card, CardHistory].each do |klass|
  klass.create_index([[:level, Mongo::ASCENDING]])
  klass.create_index([[:set_card_ids, Mongo::ASCENDING]])
  klass.create_index([[:set_external_ids, Mongo::ASCENDING]])
  klass.create_index([[:alt_card_ids, Mongo::ASCENDING]])
end

# GameVersion
GameVersion.create_index([[:version, Mongo::ASCENDING]], :unique => true)
GameVersion.create_index([[:build, Mongo::ASCENDING]], :unique => true)

# Post
Post.create_index([[:created_at, Mongo::ASCENDING]])
Post.create_index([[:slug, Mongo::ASCENDING]], :unique => true)

# User
User.create_index([[:email, Mongo::ASCENDING]], :unique => true)

# CardStat
CardStat.create_index([[:faction, Mongo::ASCENDING], [:level, Mongo::ASCENDING]])