class SyncStoreProducts
  include Sidekiq::Worker
  include DataSanitizer

  sidekiq_options :queue => :high, :retry => true

  def perform
    require "typhoeus"

    # Cache store products
    db_products = {}
    Product.each {|p| db_products[p.sku] = p}

    # Load store items
    response = Typhoeus.post("https://api3.solforgegame.com/Catalog/GetUniverse", :headers => {"User-Agent" => "ForgePost Spider (shadow@forgepost.com)"}, :ssl_verifypeer => false)
    unless response.success?
      InternalAlert.deliver(self.class, "Failed to universe", "Response:\n\n\n#{response.inspect}\n\nBody:\n\n#{response.body}")
      return
    end

    products = MultiJson.load(response.body)
    unless products["status"] == "success"
      InternalAlert.deliver(self.class, "Failed parse response from universe:\n\n\n#{response.inspect}\n\nBody:\n\n#{response.body}\n\nParsed:\n\n#{products.inspect}")
      return
    end

    # Card of the Day/Week
    category = products["result"].select {|p| p["Name"] == "inventory"}.first
    items = category["Products"].select {|p| p["ProductSku"] =~ /\.single\./ }

    items.each do |data|
      data = sanitize_data(data)

      fake_sku = data["Title"] =~ /^card/i ? "card.of.the.day" : "weekly.special"

      product = db_products[fake_sku] ||= Product.new
      product.sku = fake_sku
      product.title = data["Title"]
      product.desc = data["Blurb"]
      product.cat_desc = category["Blurb"].capitalize
      product.max_quantity = data["MaxPurchasableQty"].to_i
      product.prices = convert_prices(data["Prices"])
      product.contents = convert_contents(data["Contents"])
      product.category = fake_sku == "weekly.special" ? Product::COW : Product::COD
      product.save
    end

    # Load boosters
    category = products["result"].select {|p| p["Name"] == "forsale"}.first
    items = category["Products"].select {|p| p["ProductSku"] =~ /boosterpack|playeritem|deck|skin/ }

    items.each do |data|
      data = sanitize_data(data)

      product = db_products[data["ProductSku"]] ||= Product.new

      product.sku = data["ProductSku"]
      product.title = data["Title"]
      product.desc = data["Blurb"]
      product.cat_desc = category["Blurb"].capitalize
      product.max_quantity = data["MaxPurchasableQty"].to_i
      product.prices = convert_prices(data["Prices"])

      if data["ProductSku"] =~ /boosterpack/
        product.category = Product::BOOSTER
      elsif data["ProductSku"] =~ /playeritem/
        product.category = Product::ITEM
      elsif data["ProductSku"] =~ /deck/
        product.category = Product::DECK
      elsif data["ProductSku"] =~ /skin/
        product.category = Product::SKIN
      end

      if data["Properties"] and data["Properties"]["Factions"]
        product.factions = data["Properties"]["Factions"].map {|f| FACTION_MAP[f.downcase]}
      else
        product.factions = []
      end

      product.save
    end

    # Load gold
    category = products["result"].select {|p| p["Name"] == "forsale"}.first
    items = category["Products"].select {|p| p["ProductSku"] =~ /general\.currency\.(gold|silver)/ }

    items.each do |data|
      data = sanitize_data(data)
      if data["ProductSku"] !~ /silver$/ and ( !data["Contents"] or data["Contents"].empty? )
        next
      end

      product = db_products[data["ProductSku"]] ||= Product.new

      product.sku = data["ProductSku"]
      product.title = data["Title"]
      product.desc = data["Blurb"]
      product.cat_desc = category["Blurb"].capitalize
      product.max_quantity = data["MaxPurchasableQty"].to_i
      product.category = data["ProductSku"] =~ /silver$/ ? Product::SILVER : Product::GOLD

      product.prices = convert_prices(data["Prices"])
      product.contents = convert_contents(data["Contents"])

      if data["Properties"] and data["Properties"]["Factions"]
        product.factions = data["Properties"]["Factions"].map {|f| FACTION_MAP[f.downcase]}
      else
        product.factions = []
      end

      product.save
    end

    # Associate decks if needed
    Deck.where(:product_id => nil).only(:deck_id).each do |deck|
      next unless db_products[deck.deck_id]
      deck.set(:product_id => db_products[deck.deck_id]._id)
    end

    # Cache bust
    ["deck", "product"].each do |type|
      Rails.cache.write("#{type}-cache", Time.now.utc.to_i)
      Rails.cache.write("#{type}-data-cache", Time.now.utc.to_i)
    end
  end

  def convert_prices(prices)
    return [] unless prices

    prices.map do |price|
      Price.new(:sku => price["CurrencySku"], :quantity => price["ProductQty"].to_i, :cost => price["Cost"].to_i)
    end
  end

  def convert_contents(contents)
    return [] unless contents

    contents.map do |content|
      Content.new(:sku => content["ProductSku"], :quantity => content["Qty"].to_i)
    end
  end
end
