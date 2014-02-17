ForgePost.Helpers.cards = {
  base_start: "0123456789",
  base77: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

  encode: function(cards) {
    var list = ["1"];
    for( var key in cards ) {
      if( cards[key] <= 0 ) continue;
      list.push(ForgePost.Helpers.base.convert(cards[key].toString() + key.toString(), this.base_start, this.base77));
    }

    if( list.length == 1 ) return;

    return list.join(";");
  },
  decode: function(str) {
    var cards = {};
    if( str == "" ) return cards;

    var version = str.substring(0, str.indexOf(";"));
    var list = str.substring(str.indexOf(";") + 1).split(";");
    for( var i=0, total=list.length; i < total; i++ ) {
      var val = ForgePost.Helpers.base.convert(list[i], this.base77, this.base_start);
      cards[parseInt(val.substring(1) || 0)] = parseInt(val.substring(0, 1));
    }

    return cards;
  }
}