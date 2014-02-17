//= require libraries/jquery.js
//= require libraries/highcharts.js
//= require i18n
//= require i18n/translations
//= require bootstrap/bootstrap-alert
//= require bootstrap/bootstrap-transition
//= require bootstrap/bootstrap-dropdown
//= require bootstrap/bootstrap-button
//= require bootstrap/bootstrap-tooltip
//= require bootstrap/bootstrap-tab
//= require bootstrap/bootstrap-modal
//= require highcharts-theme
//= require_self
//= require ./card_renderer
//= require_tree ./helpers/
//= require_tree ./usercp/

var ForgePost = {PAGES: {}, Helpers: {}};
ForgePost.initialize = function() {
  $(".tt").tooltip({animation: false, placement: "right", container: $("body")});
  $(".dropdown-toggle").dropdown();

  $(".alert .close").click(function() {
      var alert = $(this).closest(".alert");
      alert.slideUp("fast", function() { alert.remove(); });
  });

  ForgePost.tooltip($(".card-tt"));
};