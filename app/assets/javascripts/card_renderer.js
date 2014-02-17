(function() {

var offsetX = 0, offsetY = 0, active_card_id, last_event, tooltip_height;

function show_loading(tooltip, tooltip_loading) {
  if( !tooltip_loading.is(":visible") ) {
    offsetY = 20;
    offsetX = 40;

    tooltip.find(".card-set, .full-game-card").remove();
    tooltip.removeClass("scale");
    tooltip.css({top: last_event.pageY - offsetY, left: last_event.pageX + offsetX});
    tooltip_loading.show();
    tooltip.show();
    tooltip_height = tooltip.height();
  }
}

ForgePost.render_tooltip = function(tooltip, card_id, card_html) {
  active_card_id = card_id;

  var html = $(card_html).hide();

  // We don't want to show the tooltip until all the assets are loaded
  var total_images = 0, loaded_images = 0;
  function check_images() {
    if( active_card_id != card_id ) return;

    loaded_images += 1;

    if( total_images == loaded_images ) {
      offsetY = 200;

      if( html.hasClass("card-set") ) {
        offsetX = -60;
        tooltip.addClass("multi");
      } else {
        offsetX = 0;
        tooltip.removeClass("multi");
      }

      tooltip.find(".loading").hide();
      tooltip.find(".card-set, .full-game-card").remove();
      tooltip.addClass("scale");

      html.show().appendTo(tooltip);
      tooltip_height = tooltip.height();
      $(document)[0].onmousemove(last_event);
    }
  }

  var imgs = html.find("img");
  total_images = imgs.length;
  imgs.load(check_images);
}

ForgePost.quick_tooltip = function(parent, card_data, event) {
  if( !ForgePost.tooltip_container ) ForgePost.tooltip_container = $("<div id='fp-card-tooltip'><div class='loading'><div class='indicator'></div><span>" + I18n.t("js.loading") + "</span></div></div>").appendTo($("body"));
  last_event = event;

  var tooltip = ForgePost.tooltip_container;
  show_loading(tooltip, tooltip.find(".loading"));

  ForgePost.render_tooltip(tooltip, card_data.card_id, card_data);

  $(document)[0].onmousemove = function(event) {
    tooltip[0].style.top = (event.pageY - offsetY) + "px";
    tooltip[0].style.left = (event.pageX + offsetX) + "px";
  }
}

ForgePost.hide_tooltip = function() {
  if( ForgePost.tooltip_container ) {
    ForgePost.tooltip_container.data("active-id", "");
    ForgePost.tooltip_container.hide();
    $(document)[0].onmousemove = null;
  }
}

ForgePost.tooltip = function(selector) {
  if( !ForgePost.tooltip_container ) ForgePost.tooltip_container = $("<div id='fp-card-tooltip'><div class='loading'><div class='indicator'></div><span>" + I18n.t("js.loading") + "</span></div></div>").appendTo($("body"));
  var tooltip = ForgePost.tooltip_container;
  var tooltip_loading = tooltip.find(".loading");

  var tooltip_xhr, show_timer, tooltip_active;


  function show_tooltip() {
    var card_id = tooltip.data("active-id");

    show_loading(tooltip, tooltip_loading);

    tooltip_active = true;

    tooltip_xhr = $.ajax(card_id, {
      error: function() {
        if( tooltip.data("active-id") != card_id ) return;
      },
      success: function(card_data) {
        if( tooltip.data("active-id") != card_id ) return;
        ForgePost.render_tooltip(tooltip, card_id, card_data);
      },
    });
  }

  selector.each(function() {
    var card = $(this);
    var card_id = card.data("tooltip");
    card.mouseenter(function(event) {
      if( tooltip_xhr ) tooltip_xhr.abort();
      tooltip.data("active-id", card_id);

      last_event = event;

      if( show_timer ) clearTimeout(show_timer);
      show_timer = setTimeout(show_tooltip, 100);
    });

    card.mouseleave(function() {
      tooltip_active = null;
      if( show_timer ) clearTimeout(show_timer);

      tooltip.data("active-id", "");
      tooltip.hide();
    });
  });

  var height = $(window).height();
  $(document)[0].onmousemove = function(event) {
    if( !tooltip_active ) return last_event = event;

    tooltip[0].style.left = (event.pageX + offsetX) + "px";

    var top = event.pageY - offsetY;
    if( (top + tooltip_height) > height ) {
      top -= Math.round(tooltip_height / 2);
    }

    tooltip[0].style.top = top + "px";
  }
}
})();