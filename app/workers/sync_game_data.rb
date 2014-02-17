class SyncGameData
  include Sidekiq::Worker
  include DataSanitizer

  sidekiq_options :queue => :medium, :retry => false

  FIELD_MAP = {"Power" => :attack=, "Health" => :hp=, "CardName" => :name=, "Art" => :image_id=, "CreatureType" => :creature_type=, "Rarity" => :rarity=, "CardID" => :card_id=, "Faction" => :faction=, "Level" => :level=, "Faction" => :faction=, "token" => :token=}

  CUSTOM_KEYWORDS = [
    {:regex => /(^draw\s|\sdraw\s|\sdraw[,\.\s])/i, :text => "Card Draw", :desc => "Draws at least one new card"},
    {:regex => /(^(put|replace)\s|\s(put|replace)\s|\s(put|replace)[,\.\s])/i, :text => "Spawns Card", :desc => "Spawns a new card, can be either a new card in an empty lane, or replacing an existing card"},
    {:regex => /enters the field/i, :text => "Enters Field", :desc => "Effects when the card enters the field (played on a lane)"}
  ]

  def perform(version, root)
    redis = Redis.current.checkout

    db_cards = {}
    Card.all.each do |card|
      db_cards[card.card_id] = card
    end

    # Load the data to disk
    require "typhoeus"

    # Load keyword map
    keyword_id_map = {}
    keyword_master_map = {}

    MultiJson.load(File.read(root.join("Game_KeywordNameMapping.json")))["keywordNameMapping"].each do |set|
      set.each do |internal, external|
        next if external =~ /^DesignName$/i or internal =~ /^DesignName$/i

        res = KeywordInfo.where(:internal => internal).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :external => external, :slug => external.parameterize, :official => true}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :new => true, :fields => {:_id => true})

        keyword_master_map[internal] = external
        keyword_master_map[external] = external

        keyword_id_map[internal] = res["_id"]
        keyword_id_map[external] = res["_id"]
      end
    end

    # Keyword info
    MultiJson.load(File.read(root.join("Game_KeywordHelpText.json")))["keywordHelpText"].each do |set|
      set.each do |key, desc|
        next if key =~ /^Keyword/i
        KeywordInfo.where(:external => key).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :desc => desc, :official => true}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
      end
    end

    # Load tests
    tests = {}

    MultiJson.load(File.read(root.join("SharedTests_Tests.json")))["tests"].each do |test|
      test = sanitize_data(test)

      update = {}
      update["$setOnInsert"] = {:created_at => Time.now.utc}

      update["$set"] = {:updated_at => Time.now.utc, :target => test["Test What"], :operator => test["Operator"], :value => test["Value"]}
      update["$set"][:require_all] = test["RequiresAllInList"] ? (test["RequiresAllInList"].downcase == "true") : false
      update["$set"][:stable_board] = test["UseStableBoardMap"] ? (test["UseStableBoardMap"].downcase == "true") : false

      if !test["TestParam"].blank?
        update["$set"][:param] = test["TestParam"]
        update["$set"][:keyword_info_id] = keyword_id_map[test["TestParam"]] if keyword_id_map[test["TestParam"]]
      else
        update["$unset"] = {}
        update["$unset"][:param] = true
        update["$unset"][:keyword_info_id] = true
      end

      AbilityTest.where(:test => test["Test"]).find_and_modify(:update => update, :upsert => true, :fields => {:_id => true})
    end

    # Help text
    help_text = {}

    MultiJson.load(File.read(root.join("Game_AssortedHelpText.json")))["assortedHelpText"].each do |set|
      set.each do |text, desc|
        next if text =~ /^CardText/i

        help_text[text] = desc

        HelpText.where(:text => text).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :desc => desc}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
        KeywordInfo.where(:external => text).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :desc => desc, :slug => text.parameterize, :offical => true}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
      end
    end

    # Load keywords
    keywords = {}

    MultiJson.load(File.read(root.join("Game_Keywords.json")))["keywords"].each do |set|
      set.each do |type, desc|
        next if type =~ /^Keyword$/i

        type = "Aggressive" if type == "Swiftness"
        if type =~ /^Move ([0-9]+)|Move$/i
          type = type.gsub("Move", "Mobility")
        end

        Keyword.where(:type => type).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :desc => desc, :base => type.split(" ", 2)[0]}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
        keywords[type] = desc
      end
    end

    # Create custom keywords
    CUSTOM_KEYWORDS.each do |data|
      KeywordInfo.where(:external => data[:text]).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :slug => data[:text].parameterize, :official => false, :desc => data[:desc]}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
    end

    # Load abilities
    abilities = {}

    Dir[root.join("*ActivatedAbilities.json")].each do |path|
      MultiJson.load(File.read(path))["activatedAbilities"].each do |ability|
        abilities[ability["CardID"]] ||= []
        abilities[ability["CardID"]] << convert_ability(ability).merge(:type => Ability::ACTIVATED)
      end
    end

    Dir[root.join("*ContinuousEffects.json")].each do |path|
      MultiJson.load(File.read(path))["continuousEffects"].each do |ability|
        abilities[ability["CardID"]] ||= []
        abilities[ability["CardID"]] << convert_ability(ability).merge(:type => Ability::CONTINUOUS)
      end
    end

    Dir[root.join("*TriggeredAbilities.json")].each do |path|
      MultiJson.load(File.read(path))["triggeredAbilities"].each do |ability|
        abilities[ability["CardID"]] ||= []
        abilities[ability["CardID"]] << convert_ability(ability).merge(:type => Ability::TRIGGERED)
      end
    end

    # Load cards
    active_ids = []

    # So we can extract keywords from text
    keyword_regex = keywords.keys
    keyword_regex.delete("Activate:")
    keyword_regex = keyword_regex.join("|")

    # Create a full backup of every card
    last_version = GameVersion.where(:created_at.lt => version.created_at).sort(:build.desc).first

    history_id_map = {}
    Card.each do |card|
      # Don't re-create if we already have an entry
      next if CardHistory.where(:live_card_id => card._id, :game_version_id => last_version._id).exists?

      attribs = card.attributes

      attribs["live_card_id"] = attribs.delete("_id")
      attribs["game_version_id"] = last_version._id
      attribs.delete("last_game_version_id")
      attribs.delete("historic_game_version_ids")
      attribs.delete("updated_at")

      history = CardHistory.create!(attribs)
    end

    # Load cards
    alt_cards = {}

    MultiJson.load(File.read(root.join("ConsolidatedCards.json"))).each do |hash_id, data|
      card_id = data["CardIdentityID"] || data["CardID"]

      # Store for later processing
      if data["ArtType"] == "AltImage"
        alt_cards[card_id] = data
      end

      next unless hash_id == card_id

      card = db_cards[card_id] ||= Card.new

      # Strip spaces from the data as they are bad at it.
      data = sanitize_data(data)

      card.external_id ||= ExternalId.generate_id(ExternalId::CARD)
      card.added_game_version_id ||= version._id
      card.alt_image_ids = []

      FIELD_MAP.each do |source, dest|
        val = card.send("#{dest.to_s.tr("=", "?")}")
        if !data[source].blank? or !val.blank?
          card.send(dest, data[source].blank? ? nil : data[source])
        end
      end

      card.category = Card::CATEGORY_MAP[data["CardType"].downcase]
      card.abilities = data["abilities"] ? data["abilities"] : {}
      card.ability_types = data["abilities"] ? data["abilities"].keys : []
      card.static_abilities = data["static_ability_text"] ? data["static_ability_text"] : []
      card.static_keywords = data["static_keyword_text"] ? data["static_keyword_text"] : []
      card.static_text = data["static_text"] ? data["static_text"] : []
      card.card_set = data["Set1Booster"] == "Yes" ? "set1" : "set1.extra"
      card.creature_prim_type = card.creature_type

      card.internal_abilities = []
      if abilities[card.card_id]
        abilities[card.card_id].each do |ability|
          card.internal_abilities << Ability.new(ability)
        end
      end

      # Parse out statics
      if card.static_keywords?
        card.keywords = []

        card.static_keywords.each do |text|
          keyword_master_map.each do |find, keyword|
            if text == find || text =~ /^#{find}\s/
              card.keywords << keyword
            end
          end
        end
      end

      # Check for anything that might have poison
      if card.static_abilities?
        card.static_abilities.each do |text|
          help_text.each_key do |type|
            if text =~ /^#{type}/
              card.keywords << type
            end
          end

          text.scan(/(#{keyword_regex})/).each do |keyword|
            card.keywords << keyword[0].split(" ", 2)[0]
          end

          CUSTOM_KEYWORDS.each do |data|
            if text =~ data[:regex]
              card.keywords << data[:text]
            end
          end
        end
      end

      # Check for any keywords
      if card.static_text?
        card.static_text.each do |text|
          help_text.each_key do |type|
            if text =~ /^#{type}/
              card.keywords << type
            end
          end
        end
      end

      new_card = card.new_record?

      # Strip out any duplicates
      card.keywords.uniq!

      # So we can come back and compile the whole set
      card.set_ids = []
      card.set_ids << data["NextCardID"] if data["NextCardID"]
      card.set_ids << data["PrevCardID"] if data["PrevCardID"]
      card.available = true

      card.save
      active_ids << card._id

      unless card.errors.empty?
        InternalAlert.deliver(self.class, "Failed to load card #{card.card_id}", "Cannot load data due to validation error: #{card.errors.inspect}\n\n#{card.attributes.inspect}\n\n\n#{data.inspect}")
      end
    end

    Card.set({:_id.nin => active_ids}, {:available => false})

    # Push alt data into the parent cards
    alt_cards.each do |card_id, data|
      card = db_cards[card_id]
      card.push(:alt_image_ids => Card.sanitize_image(data["Art"]))
      card.push(:alt_card_ids => data["CardID"])
    end

    # Recalculate the entire set of IDs
    db_cards.each_value do |card|
      card_ids, set_ids = [card._id], card.set_ids

      # Compile everything in the set
      has_data = true
      while has_data do
        has_data = nil
        Card.where(:card_id.in => set_ids, :_id.nin => card_ids).only(:card_id, :set_ids).each do |set_card|
          set_ids.concat(set_card.set_ids) if set_card.set_ids?
          set_ids << set_card.card_id
          card_ids << set_card._id

          has_data = true
        end

        card_ids.uniq!
        set_ids.uniq!
      end

      # Tokens cannot have sets right now, but will assume they could in case it changes
      if set_ids.length != 3 or card_ids.length != 3 and !card.token?
        InternalAlert.deliver(self.class, "Failed to calculate card set #{card.card_id}", "Ended with #{set_ids.inspect} / #{card_ids.inspect}\n\n#{card.attributes.inspect}")
        next
      end

      set_ids = set_ids.sort_by {|c| db_cards[c].level }
      card_ids = set_ids.map {|c| db_cards[c]._id }
      external_ids = set_ids.map {|c| db_cards[c].external_id }

      card.set(:set_external_ids => external_ids, :set_card_ids => card_ids, :set_ids => set_ids)
    end

    # Attempt to generate a set for tokens using name
    name_map = {}

    db_cards.each_value do |card|
      next unless card.token?

      name = card.name.downcase.strip
      name_map[name] ||= {:ids => [], :set_ids => []}
      name_map[name][:ids] << card._id
      name_map[name][:set_ids] << card.card_id
    end

    name_map.each do |name, data|
      data[:set_ids] = data[:set_ids].sort_by {|c| db_cards[c].level }
      data[:ids] = data[:set_ids].map {|c| db_cards[c]._id }
      Card.set({:_id.in => data[:ids]}, {:set_card_ids => data[:ids], :set_ids => data[:set_ids]})
    end

    # Scan for creature types and figure out what we can consider a primary
    types = {}
    Card.distinct(:creature_type).each {|t| types[Regexp.escape(t)] = t}

    regex = types.keys.join("|")

    relevant_types = {}
    Card.only(:static_abilities, :static_text).each do |card|
      card.static_abilities.each do |text|
        text.scan(/(#{regex})/i).each do |type|
          relevant_types[type[0]] = true
        end
      end

      card.static_text.each do |text|
        text.scan(/(#{regex})/i).each do |type|
          relevant_types[type[0]] = true
        end
      end
    end

    primary_types = {}
    types.each_value do |type|
      relevant_types.each_key do |primary|
        if type != primary and type =~ /^#{primary}\s/
          primary_types[type] = primary
        end
      end
    end

    primary_types.each do |sub, primary|
      Card.set({:creature_type => sub}, :creature_prim_type => primary)
    end

    Card.where(:creature_prim_type.nin => primary_types.values).only(:creature_prim_type, :creature_type).each do |card|
      card.set(:creature_prim_type => card.creature_type) unless card.creature_prim_type == card.creature_type
    end

    # Update creature types
    start = Time.now.utc

    map = "function() {emit({type: this.creature_prim_type}, {count: 1}); }"
    reduce = <<JS
      function(key, docs) {
        var res = {count: 1};
        docs.forEach(function(row) {
          res.count += row.count;
        });

        return res;
      }
JS

    res = Card.collection.map_reduce(map, reduce, :out => {:inline => 1}, :raw => true, :query => {:creature_type => {"$exists" => true}})
    res["results"].each do |row|
      CreatureType.where(:slug => row["_id"]["type"].parameterize).find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :text => row["_id"]["type"], :count => row["value"]["count"].to_i}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true)
    end

    # Clean out inactive types
    CreatureType.where(:updated_at.lte => start).delete_all

    # Figure out what keywords are active
    keywords = Card.where(:available => true).distinct(:keywords)

    KeywordInfo.set({:external.in => keywords}, :active => true)
    KeywordInfo.set({:external.nin => keywords}, :active => false)

    latest_version = GameVersion.sort(:build.desc).first
    if version._id == latest_version._id
      # Update card history
      SyncCardHistory.new.perform

      # Recalculate average stats
      self.calculate_averages

      # Recalculate keyword usage
      self.calculate_keywords

      # Calculate rarity counts
      self.calculate_rarities

      SyncStoreProducts.perform_async
    end

    # Bust out caches
    Rails.cache.write("card-cache", Time.now.utc.to_i)
    Rails.cache.write("card-data-cache", Time.now.utc.to_i)

  ensure
    Redis.current.checkin
  end

  def calculate_keywords
    map = <<JS
    function() {
      for( var i=0, total=this.keywords.length; i < total; i++ ) {
        emit({keyword: this.keywords[i]}, {count: 1});
        emit({keyword: this.keywords[i], faction: this.faction}, {count: 1});
      }
    }
JS

    reduce = <<JS
      function(key, docs) {
        var res = {count: 0};
        docs.forEach(function(row) {
          res.count += row.count;
        });

        return res;
      }
JS

    res = Card.collection.map_reduce(map, reduce, :out => {:inline => 1}, :raw => true)

    stats = {}
    res["results"].each do |row|
      stat = stats[row["_id"]["keyword"]] ||= {"faction_count" => {}}
      if row["_id"]["faction"]
        stat["faction_count"][row["_id"]["faction"].to_i.to_s] = row["value"]["count"].to_i
      else
        stat["count"] = row["value"]["count"].to_i
      end
    end

    stats.each do |keyword, stat|
      Card::FACTION_MAP.each_value do |id|
        stat["faction_count"][id.to_s] ||= 0
      end

      KeywordInfo.where(:external => keyword).find_and_modify(:update => {"$set" => stat}, :upsert => true, :fields => {:_id => true})
    end
  end

  def calculate_rarities
    map = <<JS
    function() {
      emit({rarity: this.rarity, faction: this.faction}, {count: 1});
    }
JS

    reduce = <<JS
      function(key, docs) {
        var res = {count: 0};
        docs.forEach(function(row) {
          res.count += row.count;
        });

        return res;
      }
JS

    res = Card.collection.map_reduce(map, reduce, :out => {:inline => 1}, :query => {:token => {"$ne" => true}, :level => 1}, :raw => true)

    stats = {}
    res["results"].each do |row|
      stat = stats[row["_id"]["faction"].to_i] ||= {"count" => 0, "rarity_count" => {}}

      stat["count"] += row["value"]["count"].to_i
      stat["rarity_count"][row["_id"]["rarity"].to_i.to_s] = row["value"]["count"].to_i
    end

    stats.each do |faction, stat|
      Card::RARITY_MAP.each_key do |id|
        next if Card::UNUSED_RARITIES[id]
        stat["rarity_count"][id.to_s] ||= 0
      end

      Faction.where(:faction_id => faction).find_and_modify(:update => {"$set" => stat.merge(:faction => Card::REVERSE_FACTION_MAP[faction], :faction_id => faction, :updated_at => Time.now.utc), "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
    end
  end

  def calculate_averages
    map = <<JS
    function() {
      emit({level: this.level, creature: this.creature_prim_type, type: #{CardStat::HEALTH}}, {count: 1, sum: this.hp});
      emit({level: this.level, faction: this.faction, type: #{CardStat::HEALTH}}, {count: 1, sum: this.hp});
      emit({level: this.level, faction: #{CardStat::GLOBAL}, type: #{CardStat::HEALTH}}, {count: 1, sum: this.hp});

      emit({level: this.level, creature: this.creature_prim_type, type: #{CardStat::ATTACK}}, {count: 1, sum: this.attack});
      emit({level: this.level, faction: this.faction, type: #{CardStat::ATTACK}}, {count: 1, sum: this.attack});
      emit({level: this.level, faction: #{CardStat::GLOBAL}, type: #{CardStat::ATTACK}}, {count: 1, sum: this.attack});
    }
JS

    reduce = <<JS
      function(key, docs) {
        var res = {count: 0, sum: 0};
        docs.forEach(function(row) {
          res.count += row.count;
          res.sum += row.sum;
        });

        return res;
      }
JS

    finalizer = <<JS
      function(key, reduced) {
        reduced.avg = reduced.count > 0 ? reduced.sum / reduced.count : 0;
        return reduced;
      }
JS

    res = Card.collection.map_reduce(map, reduce, :out => {:inline => 1}, :raw => true, :query => {:category => Card::CATEGORY_MAP["creature"]}, :finalize => finalizer)

    now = Time.now.utc
    res["results"].each do |row|
      criteria = CardStat.where(:type => row["_id"]["type"].to_i, :level => row["_id"]["level"].to_i, :faction => row["_id"]["faction"].to_i)
      unless row["_id"]["creature"].blank?
        criteria = criteria.where(:creature => row["_id"]["creature"])
      end

      criteria.find_and_modify(:update => {"$set" => {:updated_at => Time.now.utc, :count => row["value"]["count"].to_i, :avg => row["value"]["avg"].round(2)}, "$setOnInsert" => {:created_at => Time.now.utc}}, :upsert => true, :fields => {:_id => true})
    end

    CardStat.where(:updated_at.lt => now).delete_all
  end

  def load_decks(root, db_cards)
    db_decks = {}
    Deck.only(:deck_id).each {|d| db_decks[d.deck_id] = d}

    Dir[root.join("Decks_*.json")].each do |path|
      MultiJson.load(File.read(path)).each do |id, cards|
        deck = db_decks[id] || Deck.new(:deck_id => id)
        # Make an usable name
        unless deck.name?
          deck.set_type, type, name = id.split(".", 3)

          if name.blank?
            name, type = type, nil
          end

          if name =~ /\.demo$/
            name.gsub!(/\.demo$/, "")
            deck.category = "demo"
          else
            deck.category = type
          end

          deck.name = name.titleize
          deck.name.tr!(".", " ")
        end

        deck.card_ids, deck.quantities, deck.factions = [], [], []
        cards.each do |row|
          next unless db_cards[row["CardID"]]
          deck.factions << db_cards[row["CardID"]].faction
          deck.card_ids << db_cards[row["CardID"]]._id
          deck.card_external_ids << db_cards[row["CardID"]].external_id
          deck.quantities << row["Count"].to_i
        end

        unless deck.card_ids.length == deck.quantities.length and deck.quantities.length == cards.length
          InternalAlert.deliver(self.class, "Failed to laod cards for deck #{id}", "#{deck.attributes.inspect}\n\n#{cards.inspect}\n\n#{id}\n\n#{db_cards.keys}")
          next
        end

        deck.factions.uniq!

        # Load deck info
        response = Typhoeus.post("https://api3.solforgegame.com/Catalog/GetProduct", :headers => {"User-Agent" => "ForgePost Spider (shadow@forgepost.com)"}, :body => MultiJson.dump(:productSku => id, :throwOnMissing => false), :ssl_verifypeer => false)
        unless response.success?
          InternalAlert.deliver(self.class, "Failed to load deck #{id}", "#{deck.attributes.inspect}\n\nResponse:\n\n\n#{response.inspect}\n\nBody:\n\n#{response.body}")
          next
        end

        body = MultiJson.load(response.body)
        unless body["status"] == "success"
          InternalAlert.deliver(self.class, "Failed to load deck #{id}", "#{deck.attributes.inspect}\n\nResponse:\n\n\n#{response.inspect}\n\nBody:\n\n#{response.body}\n\nParsed:\n\n#{body.inspect}")
          next
        end

        if body["result"]
          deck.name = body["result"]["Title"]
          deck.desc = body["result"]["Blurb"]
        end

        deck.save
      end
    end
  end

  # Various helpers
  def convert_ability(ability)
    converted = {}
    converted[:desc] = ability["AbilityText"]

    converted[:source] = ability["Trigger Source"] if ability["Trigger Source"]
    converted[:triggers] = ability["Triggers When"] if ability["Triggers When"]

    converted[:num_targets] = ability["Number of Targets"]
    converted[:beneficial] = ability["BeneficialEffect"] ? (ability["BeneficialEffect"].downcase == "true") : false

    converted[:target] = ability["Target"] if ability["Target"]
    converted[:prompt] = ability["TargetPrompt"] if ability["TargetPrompt"]

    converted[:effect] = ability["Effect"] || ability["Continuous Effect"]

    converted[:condition] = ability["Condition"] if ability["Condition"]
    converted[:cond_target] = ability["ConditionalTestTarget"] if ability["ConditionalTestTarget"]

    converted[:effect_values] = []
    if ability["Effect Value"]
      ability["Effect Value"].each do |value|
        converted[:effect_values] << value.split(",").map {|v| v.strip}
      end
    end

    converted[:tests] = []
    ability.each do |key, value|
      next unless key =~ /^TargetTest([0-9]+)$/
      converted[:tests] << value
    end

    converted[:cond_tests] = []
    ability.each do |key, value|
      next unless key =~ /^ConditionalTest([0-9]+)$/
      converted[:cond_tests] << value
    end

    converted
  end
end
