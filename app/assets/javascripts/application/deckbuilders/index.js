ForgePost.PAGES["deckbuilders/index"] = function() {
  $("#loading").modal("show");

  if( typeof(window.card_data) == "object" ) {
    ForgePost.PAGES["deckbuilders/index/ready"](window.card_data);
  } else {
    $(document).ready(function() {
      ForgePost.PAGES["deckbuilders/index/ready"](window.card_data);
    });
  }
}

ForgePost.PAGES["deckbuilders/index/ready"] = function(card_data) {
  if( typeof(window.card_data) != "object" ) return;
  delete(window.card_data);

  var scope = $("#deckbuilders_index");
  $("html").addClass("noselect");

  var total_cards = card_data.length;
  var uniq_id = 0;
  var config = {}, deck_cards = {}, deck_offsets = {}, id_map = {};
  config.level = 3;
  config.sort_by = "rarity_faction_name";

  var has_inventory = card_inventory !== null;

  // Manage config
  var manage = $("#manage");

  config.force_inventory = false;

  // Showing preview without loading bits
  var active_card_id;
  var preview = $("#preview");
  function show_card_preview(card_id) {
    active_card_id = card_id;

    var html = $(card_data[card_id].html).hide();

    var total_images = 0, loaded_images = 0;
    function check_images() {
      if( active_card_id != card_id ) return;

      loaded_images += 1;

      if( total_images == loaded_images ) {
        preview.find(".full-game-card").remove();
        html.show().appendTo(preview);
      }
    }

    var imgs = html.find("img");
    total_images = imgs.length;
    imgs.load(check_images);
  }

  // Render all the cards and deal with card previews
  var card_rows = {}, attach_states = {}, card_count = {}, first_id;
  var card_ids = [];
  for( var i=0; i < total_cards; i++ ) {
    var card = card_data[i];

    card.internal_id = i;

    id_map[card.card_id] = i;

    var html = "";

    html += "<li data-internal-id=" + i + " data-card-id=" + card.card_id + ">";
    html += "<div class='img'><img src='" + card.art + "'></div>";
    html += "<div class='info'>";
    html += "<div class='primary'>";
    if( has_inventory && card_inventory[card.id] && card_inventory[card.id] > 0 ) {
      html += "<div class='quantity'><span>" + card_inventory[card.id] + "</span><span>x</span></div>";
    }

    html += "<div class='name rarity-" + card.rarity + "'>" + card.name + "</div>";
    html += "</div>";

    html += "<div class='data'>";

    html += "<div class='type'>";
    html += I18n.t("js.categories." + card.category);
    if( card.creature ) html += " - " + card.creature;
    html += "</div>";

    html += "<div class='faction faction-" + card.faction + "'>" + I18n.t("js.factions." + card.faction) + "</div>";
    html += "<div class='stats'>";
    if( card.atk ) html += "<div class='atk'>" + I18n.t("js.atk") + " <span>" + card.atk + "</span></div>";
    if( card.hp ) html += "<div class='hp'>" + I18n.t("js.hp") + " <span>" + card.hp + "</span</div>";
    html += "</div>";
    html += "</div>";
    html += "</div>";
    html += "</li>";

    card_rows[i] = $(html);
    card_ids.push(i);

    if( card.level != config.level ) {
      attach_states[i] = false;
      card_rows[i].hide();
    } else {
      attach_states[i] = true;

      if( !first_id ) first_id = i;
    }
  }

  show_card_preview(first_id);

  var list = $("#cards .well ul");
  for( var i=0; i < total_cards; i++ ) {
    card_rows[i].appendTo(list);
  }

  $("#cards .well").on("mouseenter", "ul li", function() {
    show_card_preview($(this).data("internal-id"));
  });

  $("#deck .well").on("mouseenter", ".deck-card", function(event) {
    if( $("#search:visible").length == 1 ) {
      show_card_preview($(this).data("internal-id"));
    } else {
      ForgePost.quick_tooltip($(this), card_data[$(this).data("internal-id")].html, event);
    }
  }).on("mouseleave", ".deck-card", function() {
    ForgePost.hide_tooltip()
  });

  $("#summary .well, #manage .well").mouseenter(function() {
    $("html").removeClass("noselect");
  });

  $("#summary .well, #manage .well").mouseleave(function() {
    $("html").addClass("noselect");
  });

  // Sort cards
  var sort_modes = {
    rarity_faction_name: function(a, b) {
      if( card_data[a].rarity < card_data[b].rarity ) return 1;
      if( card_data[a].rarity > card_data[b].rarity ) return -1;

      if( card_data[a].faction < card_data[b].faction ) return -1;
      if( card_data[a].faction > card_data[b].faction ) return 1;

      if( card_data[a].name < card_data[b].name ) return -1;
      if( card_data[a].name > card_data[b].name ) return 1;

      return 0;
    },

    faction_rarity: function(a, b) {
      if( card_data[a].faction < card_data[b].faction ) return -1;
      if( card_data[a].faction > card_data[b].faction ) return 1;

      if( card_data[a].rarity < card_data[b].rarity ) return 1;
      if( card_data[a].rarity > card_data[b].rarity ) return -1;

      if( card_data[a].name < card_data[b].name ) return -1;
      if( card_data[a].name > card_data[b].name ) return 1;

      return 0;
    },

    name: function(a, b) {
      if( card_data[a].name < card_data[b].name ) return -1;
      if( card_data[a].name > card_data[b].name ) return 1;

      return 0;
    },

    health: function(a, b) {
      if( card_data[a].hp < card_data[b].hp ) return 1;
      if( card_data[a].hp > card_data[b].hp ) return -1;

      return 0;
    },

    attack: function(a, b) {
      if( card_data[a].atk < card_data[b].atk ) return 1;
      if( card_data[a].atk > card_data[b].atk ) return -1;

      return 0;
    }
  }

  function sort_cards(mode) {
    card_ids.sort(sort_modes[mode]);

    var list = $("#cards .well ul");
    for( var i=0, total=card_ids.length; i < total; i++ ) {
      var row_id = card_ids[i];
      card_rows[row_id].detach();
      card_rows[row_id].appendTo(list);
    }
  }

  // Card visibility if we hit 3
  function card_status(internal_id, enable) {
    if( enable ) {
      card_rows[internal_id].removeClass("limit-hit");
    } else {
      card_rows[internal_id].addClass("limit-hit");
    }
  }

  // Filtering of cards
  var search = $("#search");

  function update_cards() {
    // Grab the filters
    var factions = {};
    $("#factions .btn").each(function() {
      var row = $(this);
      if( row.hasClass("active") ) factions[row.data("key")] = true;
    });

    var rarities = {};
    $("#rarities .btn").each(function() {
      var row = $(this);
      if( row.hasClass("active") ) rarities[row.data("key")] = true;
    });

    var category = $("#categories li.active a").data("key");
    if( category == "all" ) category = null;
    var keywords = $("#keywords li.active a").data("key");
    if( keywords == "all" ) keywords = null;
    var creature = $("#creatures li.active a").data("key");
    if( creature == "all" ) creature = null;

    var name = $.trim($("#name input").val());
    if( name != "" ) {
      name = new RegExp(name, "i");
    }

    // Start filtering
    var active_cards = {};
    var has_active = null;
    for( var i=0; i < total_cards; i++ ) {
      var card = card_data[i];
      if( card.level != config.level ) continue;

      // Name
      if( name && !card.name.match(name) ) continue;

      // Rarity
      if( !rarities[card.rarity] ) continue;

      // Faction
      if( !factions[card.faction] ) continue;

      // Category
      if( category != null && card.category != category ) {
        continue;
      }

      // Keywords
      if( keywords != null && $.inArray(keywords, card.keywords) == -1 ) {
        continue;
      }

      // Creature
      if( creature != null && creature != card.creature_prim ) continue;

      // Inventory
      if( config.force_inventory && has_inventory ) {
        if( !card_inventory[card.id] || card_inventory[card.id] <= 0 || ( card_count[card.card_id] && card_count[card.card_id] >= card_inventory[card.id] ) ) {
          continue;
        }
      }

      active_cards[i] = true;
      has_active = true;
    }

    $("#no-cards")[has_active ? "hide" : "show"]();

    var first_id;
    for( var i=0; i < total_cards; i++ ) {
      if( active_cards[i] && !attach_states[i] ) {
        card_rows[i].show();
        attach_states[i] = true;

      } else if( !active_cards[i] && attach_states[i] ) {
        card_rows[i].hide();
        attach_states[i] = false;
      }

      if( !first_id && attach_states[i] ) {
        first_id = i;
      }
    }

    if( first_id ) {
      show_card_preview(first_id);
    }
  }

  search.find(".btn-group .btn").click(update_cards);
  search.find(".dropdown-menu a").click(update_cards);
  search.find("input[type='text']").keyup(update_cards);

  search.find(".reset").click(function() {
    search.find(".btn-group a").addClass("active");
    search.find("input[type='text']").val("");
    search.find(".dropdown-menu").each(function() {
      var dropdown = $(this);
      dropdown.find("li.active").removeClass("active");
      dropdown.find("li:first a").click();
    });

    config.level = parseInt($("#levels li.active a").data("key"))
    update_cards();
  });


  // Card management
  function construct_deck_card(internal_id, card) {
    if( typeof(card) != "object" ) {
      console.log("WARNING: Unknown internal id " + internal_id + " given, cannot load card.");
      return;
    }

    var html = "<div class='deck-card' style='background-image: url(\"" + card.art_medium + "\")' data-internal-id=" + internal_id + ">";
    html += "<div class='name rarity-" + card.rarity +"'>" + card.name + "</div>";
    html += "<div class='data'>";

    html += "<div class='faction faction-" + card.faction + "'>" + I18n.t("js.factions." + card.faction) + "</div>";
    html += "<div class='stats'>";
    if( card.atk ) html += "<div class='atk'>" + I18n.t("js.atk") + " <span>" + card.atk + "</span></div>";
    if( card.hp ) html += "<div class='hp'>" + I18n.t("js.hp") + " <span>" + card.hp + "</span</div>";
    html += "</div>";
    html += "</div>";

    return $(html);
  }

  // Update card level
  var deck_container = $("#deck .well");

  $("#sort-by li a").click(function(event) {
    event.preventDefault();

    var dropdown = $(this).closest(".dropdown");
    var label = dropdown.find(".dropdown-toggle span");
    label.html($(this).data("prefix") + " <span>" + $(this).text() + "</span>");

    dropdown.find("li.active").removeClass("active");
    $(this).closest("li").addClass("active");

    var sort_by = $("#sort-by li.active a").data("key");
    sort_cards(sort_by);
  });

  $("#levels li a").click(function(event) {
    event.preventDefault();

    // Update label
    var dropdown = $(this).closest(".dropdown");
    var label = dropdown.find(".dropdown-toggle span");
    label.html($(this).data("prefix") + " <span>" + $(this).text() + "</span>");

    dropdown.find("li.active").removeClass("active");
    $(this).closest("li").addClass("active");

    // Search
    var level = parseInt($("#levels li.active a").data("key"));

    if( config.level == level ) return;
    config.level = level;

    // Update card list
    update_cards();

    // For shifting the IDs around
    var id_to_card = {};
    for( var i=0; i < total_cards; i++ ) {
      var card = card_data[i];
      id_to_card[card.id] = i;
    }

    var internal_id_map = {};
    var temp = {};


    for( var internal_id in deck_cards ) {
      var leveled_card = card_data[id_to_card[card_data[internal_id].set_card_ids[level - 1]]];
      internal_id_map[internal_id] = leveled_card.internal_id;

      // Move card counts
      temp[leveled_card.card_id] = card_count[card_data[internal_id].card_id];

      // Redo the deck card
      for( var i=0, total=deck_cards[internal_id].length; i < total; i++ ) {
        var row = deck_cards[internal_id][i];
        var top = row.css("top");
        var left = row.css("left");
        var uniq_id = row.data("uniq-id");
        var zindex = row.css("z-index");

        row.remove();

        var deck_card = construct_deck_card(leveled_card.internal_id, leveled_card);
        deck_card.css("top", top);
        deck_card.css("left", left);
        deck_card.css("z-index", zindex);
        deck_card.data("uniq-id", uniq_id);
        deck_card.appendTo(deck_container);

        deck_cards[internal_id][i] = deck_card;
      }
    }

    // Copy everything back over
    card_count = temp;

    temp = {};

    for( var internal_id in deck_cards ) {
      temp[internal_id_map[internal_id]] = deck_cards[internal_id];
    }
    deck_cards = temp;

    var temp = {};
    for( var internal_id in deck_offsets ) {
      temp[internal_id_map[internal_id]] = deck_offsets[internal_id];
    }
    deck_offsets = temp;

    // Now go back and translate it
    store_deck();
  });

  // Update card status based on inventory
  function update_card_inventory(internal_id) {
    if( !has_inventory ) return;

    var inventory = card_inventory[card_data[internal_id].id];
    if( !inventory || inventory == 0 ) return;

    var leftover = Math.max(inventory - card_count[card_data[internal_id].card_id], 0);
    card_rows[internal_id].find(".quantity span:first").text(leftover);

    if( !config.force_inventory ) return;

    // Ran out of cards, hide it
    if( leftover <= 0 ) {
      if( attach_states[internal_id] ) {
        card_rows[internal_id].hide();
        attach_states[internal_id] = false;
      }
    // Have enough again, can show it
    } else if( !attach_states[internal_id] ) {
      attach_states[internal_id] = true;
      card_rows[internal_id].show();
    }
  }

  // Remove a card
  function remove_card(card) {
    var internal_id = card.data("internal-id");
    var card_id = card_data[internal_id].card_id;
    if( card_count[card_id] == 3 ) {
      card_status(internal_id, true);
    }

    card_count[card_id] -= 1;

    var empty_deck;
    if( deck_container.find(".deck-card").length == 1 ) {
      $("#deck-empty").fadeIn(100);
      empty_deck = true;
    }

    card.remove();

    var uniq_id = card.data("uniq-id");
    for( var i=0, total=deck_cards[internal_id].length; i< total; i++ ) {
      if( deck_cards[internal_id][i].data("uniq-id") == uniq_id ) {
        deck_cards[internal_id].splice(i, 1);
        break;
      }
    }

    if( card_count[card_id] <= 0 ) {
      delete(deck_cards[internal_id]);
      delete(deck_offsets[internal_id]);

      organize_cards(internal_id);
    }

    store_deck(empty_deck);

    ForgePost.hide_tooltip();

    // Update the card list quantity
    update_card_inventory(internal_id);
  }

  // Add a card
  function add_card(card_data) {
    var deck_card = construct_deck_card(card_data.internal_id, card_data);
    var internal_id = deck_card.data("internal-id");
    if( !deck_offsets[internal_id] ) deck_offsets[internal_id] = {};

    var card_id = card_data.card_id;

    var pos = deck_container.position();
    deck_card[0].style.top = pos.top + "px";
    deck_card[0].style.left = pos.left + "px";
    if( !card_count[card_id] ) card_count[card_id] = 0;
    card_count[card_id] += 1;

    if( card_count[card_id] >= 3 ) {
      card_status(internal_id, false);
    }

    $("#deck-empty").hide();

    // Remove the
    deck_card[0].style.zIndex = "auto";
    deck_card.appendTo(deck_container);

    if( !deck_cards[internal_id] ) deck_cards[internal_id] = [];
    deck_cards[internal_id].push(deck_card);
    deck_card.data("uniq-id", uniq_id += 1);

    organize_cards(internal_id);

    store_deck();
    update_card_inventory(internal_id);
  }

  // Block the right click menu when running under click controls
  $("#cards, #deck").contextmenu(function(event) {
    event.preventDefault();

    var card = $(event.target).closest("li, .deck-card");

    var internal_id = card.data("internal-id");
    if( event.which == 3 && deck_cards[internal_id] ) {
      remove_card(deck_cards[internal_id][deck_cards[internal_id].length - 1]);
    }
  });

  // Card management
  function add_card_event(event) {
    if( event.which != 1 ) return;

    var internal_id = $(this).data("internal-id");

    var card_id = card_data[internal_id].card_id
    if( card_count[card_id] && card_count[card_id] >= 3 ) return;

    add_card(card_data[$(this).data("internal-id")]);
  }

  var has_focus;
  var search_input = $("#search input[type='text']");
  $("#cards .well ul li").mousedown(function() {
    has_focus = !!search_input.has("focus");
  });

  $("#cards .well ul li").mouseup(function() {
    if( has_focus ) {
      search_input.focus();
    }
  });

  $("#cards .well ul li").click(add_card_event);
  $("#deck .well").on("click", ".deck-card", add_card_event);

  // Card controls
  var cards_box, deck_box;
  function calculate_boxes() {
    if( cards_box || deck_box ) return;

    var pos = $("#cards").position();
    cards_box = {};
    cards_box.top = pos.top;
    cards_box.left = pos.left;
    cards_box.bottom = pos.top + $("#cards").height();
    cards_box.right = pos.left + $("#cards").width();

    pos = $("#deck").position();

    deck_box = {};
    deck_box.top = pos.top;
    deck_box.left = pos.left;
    deck_box.bottom = pos.top + $("#deck").height();
    deck_box.right = pos.left + $("#deck").width();
  }

  // Handle resizing to recache our bounding boxes
  // as well as fixing all the out of bound cards
  var snap_cards;
  $(window).resize(function() {
    cards_box = null, deck_box = null;

    if( snap_cards ) clearTimeout(snap_cards);
    snap_cards = setTimeout(organize_cards, 500);
  });

  // Showing/hiding the preview/search UI
  $("#toggle-search").click(function(event) {
    event.preventDefault();

    var offset = $("#preview-search").height();

    if( !$("#preview-search").is(":visible") ) {
      $("#preview-search").show();
      $(this).text(I18n.t("js.hide_search"));
    } else {
      $("#preview-search").hide();
      $(this).text(I18n.t("js.show_search"));
      offset *= -1;
    }

    cards_box = null, deck_box = null;
    deck_container.find(".deck-card").each(function() {
      this.style.top = (parseInt(this.style.top) + offset) + "px";

      deck_offsets[$(this).data("internal-id")].y += offset;
    });
  });

  // Figure out stats about the deck
  var stat_fields = {}, cat_fields = {}, fact_fields = {}, rarity_fields = {};
  scope.find("#summary dd").each(function() {
    var klass = $(this).attr("class");
    if( klass == "category" ) {
      cat_fields[$(this).data("category")] = $(this);
    } else if( klass == "faction" ) {
      fact_fields[$(this).data("faction")] = $(this);
    } else if( klass == "rarity" ) {
      rarity_fields[$(this).data("rarity")] = $(this);
    } else {
      stat_fields[klass] = $(this);
    }
  });

  var no_precision = {precision: 0};
  function calculate_stats() {
    var total = 0;

    var categories = {}, factions = {}, rarities = {};
    for( var card_id in card_count ) {
      var quantity = card_count[card_id];
      if( quantity <= 0 ) continue;

      var card = card_data[id_map[card_id]];

      total += quantity;

      if( !categories[card.category] ) categories[card.category] = 0;
      categories[card.category] += quantity;

      if( !factions[card.faction] ) factions[card.faction] = 0;
      factions[card.faction] += quantity;

      if( !rarities[card.rarity] ) rarities[card.rarity] = 0;
      rarities[card.rarity] += quantity;
    }

    stat_fields["total-cards"].text(total);

    for( var id in cat_fields ) {
      cat_fields[id].text(categories[id] || 0);
    }

    for( var id in rarity_fields ) {
      rarity_fields[id].text(rarities[id] || 0);
    }

    for( var id in fact_fields ) {
      if( factions[id] && factions[id] > 0 ) {
        fact_fields[id].text(factions[id]);
        $("#summary .faction[data-faction=" + id + "]").show();

      } else {
        $("#summary .faction[data-faction=" + id + "]").hide();
      }
    }
  }

  // Handle positioning cards on the board automatically
  function organize_cards(changed_id, skip_animation) {
    calculate_boxes();

    var xOffsetStart = deck_box.left + 36;
    var xOffset = xOffsetStart, yOffset = deck_box.top + 10;

    // We don't need to reposition everything if the card is already organized
    if( changed_id != null && card_count[card_data[changed_id].card_id] > 1 && deck_offsets[changed_id] ) {
      var cards = deck_cards[changed_id];
      yOffset = deck_offsets[changed_id].y;
      xOffset = deck_offsets[changed_id].x;

      var yPad = 20;
      for( var i=1, total=cards.length; i < total; i++ ) {
        cards[i][0].style.zIndex = i;
        cards[i][0].style.top = (yOffset + yPad) + "px";
        cards[i][0].style.left = xOffset + "px";

        yPad += 20;
      }

      return;
    }

    var list = deck_container.find(".deck-card");
    var maxX = deck_box.right + 50;
    var width = list.first().width() + 5;
    var height = list.first().height() + 30;

    // We're modifying the position of everything at >= this card
    // Figure out the position of something we can anchor to reduce the work
    if( changed_id != null && !deck_cards[changed_id] ) {
      var last_card;
      for( var internal_id=0; internal_id < changed_id; internal_id++ ) {
        if( deck_cards[internal_id] ) {
          last_card = internal_id;
        }
      }

      if( last_card ) {
        yOffset = deck_offsets[last_card].y;
        xOffset = deck_offsets[last_card].x + width;
        if( xOffset >= maxX ) {
          yOffset += height;
          xOffset = xOffsetStart;
        }

      } else {
        changed_id = null;
      }
    } else {
      changed_id = null;
    }

    // Reposition
    var anim_opts = {duration: 100, queue: false, easing: "linear"};
    for( var internal_id=(changed_id || 0); internal_id < total_cards; internal_id++ ) {
      var cards = deck_cards[internal_id];
      if( !cards ) continue;

      var card_id = card_data[internal_id].card_id;
      if( (xOffset + width) >= maxX ) {
        yOffset += height;
        xOffset = xOffsetStart;
      }

      var yPad = 0;
      for( var i=0, total=card_count[card_id]; i < total; i++ ) {
        cards[i][0].style.zIndex = i;

        if( !skip_animation ) {
          cards[i].stop();
          cards[i].animate({top: (yOffset + yPad) + "px", left: xOffset + "px"}, anim_opts);
        } else {
          cards[i][0].style.top = (yOffset + yPad) + "px";
          cards[i][0].style.left = xOffset + "px";
        }


        yPad += 20;
      }

      deck_offsets[internal_id].x = xOffset;
      deck_offsets[internal_id].y = yOffset;

      xOffset += width;
    }

    deck_container.css("height", yOffset - deck_box.top + (height * 2));
  }

  // Bulk adding of cards
  var run_id = 0;
  function bulk_add_cards(card_ids) {
    $("#deck-empty").hide();

    if( !deck_cards ) deck_cards = {};
    if( !deck_offsets ) deck_offsets = {};
    run_id += 1;

    config.level = null;
    for( var card_id in card_ids ) {
      var quantity = card_ids[card_id];
      var internal_id = id_map[card_id];
      var card = card_data[internal_id];

      if( config.level != card.level ) {
        config.level = card.level;
        update_cards();
        $("#levels li a[data-key=" + config.level + "]").click();
      }

      if( !deck_offsets[internal_id] ) deck_offsets[internal_id] = {};

      card_count[card_id] = quantity;
      if( quantity >= 3 ) card_status(internal_id, false);
      update_card_inventory(internal_id);

      if( !deck_cards[internal_id] ) deck_cards[internal_id] = [];

      for( var i=0; i < quantity; i++ ) {
        var deck_card = deck_cards[internal_id][i];
        if( !deck_card ) {
          deck_card = construct_deck_card(internal_id, card);
          deck_card.data("uniq-id", uniq_id += 1);
          deck_card.appendTo(deck_container);
          deck_cards[internal_id].push(deck_card);
        }

        deck_card.data("marked", run_id);
      }
    }

    if( run_id > 1 ) {
      for( var internal_id in deck_cards ) {
        var list = [];
        for( var i=0, total=deck_cards[internal_id].length; i < total; i++ ) {
          if( deck_cards[internal_id][i].data("marked") == run_id ) {
            list.push(deck_cards[internal_id][i]);
          } else {
            deck_cards[internal_id][i].remove();
          }
        }

        if( list.length == 0 ) {
          delete(deck_cards[internal_id]);
          delete(deck_offsets[internal_id]);
          card_count[card_data[internal_id].card_id] = 0;

          card_status(internal_id, true);
          update_card_inventory(internal_id);

        } else {
          deck_cards[internal_id] = list;
        }

      }
    }

    if( !config.level ) config.level = 3;

    organize_cards(null, true);
    calculate_stats();
  }


  if( window.location.hash != "" && window.location.hash.match(/;/) ) {
    bulk_add_cards(ForgePost.Helpers.cards.decode(window.location.hash.substring(1)));

    setTimeout(function() {
      $("#loading").modal("hide");
    }, 200);
  } else {
    $("#loading").modal("hide");
  }

  // Add historical data for changing cards on hash changes automatically
  var new_hash = null;
  $(window).on("hashchange", function() {
    if( new_hash == window.location.hash ) return;
    bulk_add_cards(ForgePost.Helpers.cards.decode(window.location.hash.substring(1)));
  });


  // And create the URL to store data in
  function store_deck(empty_deck) {
    var str = ForgePost.Helpers.cards.encode(card_count);
    new_hash = str ? ("#" + str) : null;
    if( empty_deck ) new_hash = "";
    window.location.hash = str || "";

    calculate_stats();
  }

  // Exporting and importing of a card list
  function export_deck(type) {
    var list = {};

    for( var card_id in card_count ) {
      var quantity = card_count[card_id];
      if( quantity <= 0 ) continue;

      var card = card_data[id_map[card_id]];
      if( !list[card.faction] ) list[card.faction] = [];

      list[card.faction].push([quantity, card]);
    }

    var lines = [];
    if( type == "plaintext" ) {
      lines.push(I18n.t("js.deck_url", {url: window.location.href}));
    } else if( type == "bbcode" ) {
      lines.push("[url=" + window.location.href + "]ForgePost Deck Page[/url]");
    } else if( type == "html" ) {
      lines.push("<a href='" + window.location.href + "'>ForgePost Deck URL</a>");
    } else if( type == "markdown" ) {
      lines.push("[ForgePost Deck URL](" + window.location.href + ")  ");
    }

    lines.push("");

    for( var faction in list ) {
//      var text = I18n.t("js.factions." + faction);
//      if( type == "markdown" ) text = "**" + text + "**  ";
//
//      lines.push(text);

      var cards = list[faction];
      cards.sort(function(a, b) { return b[1].rarity - a[1].rarity });

      for( var i=0, total=cards.length; i < total; i++ ) {
        var quantity = cards[i][0];
        var card = cards[i][1];

        var text = card.name;
        if( type == "bbcode" ) {
          text = "[url=" + card.url + "]" + text + "[/url]";
        } else if( type == "html" ) {
          text = "<a href='" + card.url + "'>" + text + "</a>";
        } else if( type == "markdown" ) {
          text = "[" + text + "](" + card.url + ")  ";
        }

        lines.push(quantity + " x " + text);
      }
    }

    $("#" + type + " textarea").val(lines.join("\n"));
  }

  $("#export-cards").click(function(event) {
    event.preventDefault();

    export_deck("plaintext");
    $("#deck-export").modal();
  });

  $("#deck-export ul li a").click(function(event) {
    event.preventDefault();

    var li = $(this).closest("li");
    var id = $(this).attr("href").replace("#", "");

    $("#deck-export ul li.active").removeClass("active");
    li.addClass("active");

    $(".tab-pane.active").removeClass("active");
    $("#" + id).addClass("active");

    export_deck(id);
  });

  // Import
  $("#deck-import .pull-right").click(function(event) {
    event.preventDefault();

    var imported_cards = {};
    var name_map = {};

    for( var i=0; i < total_cards; i++ ) {
      var card = card_data[i];
      if( config.level != card.level ) continue;

      name_map[card.name.toLowerCase()] = card.card_id;
    }

    var deck = $("#deck-import textarea").val();
    deck = deck.split("\n");

    for( var i=0, total=deck.length; i < total; i++ ) {
      var line = deck[i];
      line = line.replace(/^[0-9]+\)/, "");

      var match = line.match(/^([0-9]+).|.([0-9]+)$/);
      if( !match ) continue;

      var quantity = parseInt(match[0].replace(/[^0-9]+/, ""));
      var card = line;

      // Strip out quantities
      if( line.match(/^[0-9]+./) ) {
        card = card.replace(/^[0-9]+./, "");
      } else if( line.match(/.[0-9]+$/) ) {
        card = card.replace(/.[0-9]+$/, "");
      }

      card = card.replace(/^[\sx*\-]+|[\sx*\-]+$/i, "");
      card = card.toLowerCase();

      if( name_map[card] ) {
        imported_cards[name_map[card]] = quantity;
      }
    }

    bulk_add_cards(imported_cards);
    store_deck();
    $("#deck-import").modal("hide");
  });

  $("#import-cards").click(function(event) {
    event.preventDefault();
    $("#deck-import").modal();
  });

  $("#usage").click(function(event) {
    event.preventDefault();
    $("#help").modal();
  });

  // Deck saving/restoring
  function deck_hooks(scope) {
    scope.find("#new-deck form").submit(function(event) {
      event.preventDefault();
      var button = $(this).find("input[type='submit']")
      button.button("loading");

      var error = scope.find("#new-deck form p").slideUp("fast");
      $.ajax($(this).attr("action"), {
        type: "POST",
        data: {name: $(this).find("input[type='text']").val(), cards: card_count},
        error: function(res) {
          res = JSON.parse(res.responseText);
          error.slideDown("fast").text(res.msg);
          button.button("reset");
        },
        success: function(res) {
          $("#deck-storage").modal("hide");
        }
      });
    });

    scope.find(".overwrite input").click(function(event) {
      event.preventDefault();

      $(this).button("loading");
      $.ajax($(this).data("target"), {
        type: "POST",
        data: {cards: card_count},
        success: function(res) {
          $("#deck-storage").modal("hide");
        }
      });
    });
  }


  $("#save-deck").click(function(event) {
    event.preventDefault();
    var body = $("#deck-storage .modal-body");
    var loading = body.find(".loading");
    loading.show();

    $.ajax($(this).data("target"), {
      cache: false,
      success: function(res) {
        loading.hide();
        body.find(".content").html(res);
        deck_hooks(body);
      }
    });

    $("#deck-storage").modal("show");
  });

  $("#load-deck").click(function(event) {
    event.preventDefault();
    var body = $("#deck-list .modal-body");
    var loading = body.find(".loading");
    loading.show();

    $.ajax($(this).data("target"), {
      cache: false,
      success: function(res) {
        loading.hide();
        body.find(".content").html(res);

        body.find(".delete a").click(function(event) {
          event.preventDefault();
          if( !confirm(I18n.t("js.delete_confirm")) ) return;
          $(this).button("loading");

          var scope = $(this);
          $.ajax($(this).data("target"), {
            type: "DELETE",
            success: function() {
              $("#load-deck").click();
            }
          });
        });

        body.find(".load a").click(function(event) {
          $("#deck-list").modal("hide");
        });
      }
    });

    $("#deck-list").modal("show");
  });

  // Key bindings
  var factions = {};
  $("#factions a").each(function() {
    var row = $(this);
    factions[row.data("abbrev")] = row;
  });

  $(document).keypress(function(event) {
    if( $(event.target).is(":focus") ) return;

    var key = String.fromCharCode(event.keyCode);

    // Level filter
    if( $.isNumeric(key) && key >= 1 && key <= 3 && parseInt(key) != config.level ) {
      $("#levels li.active").removeClass("active");
      var a = $("#levels li a[data-key=" + key + "]");
      a.closest("li").addClass("active");
      a.click();
    // Faction filters
    } else if( factions[key] ) {
      factions[key].click();
    }

  });
}