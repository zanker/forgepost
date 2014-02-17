ForgePost.PAGES["sessions/new"] = function() {
  var scope = $("#sessions_new");
  scope.find("form").submit(function(event) {
    event.preventDefault();

    $(this).find("input[type='submit']").button("loading");

    var data = {};
    data.email = $.trim($("#user_email").val());
    data.password = $.trim($("#user_password").val());

    $.ajax($(this).attr("action"), {
      type: "POST",
      data: data,
      error: function(xhr) {
        scope.find("input[type='submit']").button("reset");

        ForgePost.Helpers.Errors.handle_errors(scope, xhr);
      },
      success: function(res) {
        window.location = "/usercp/cards";
      }
    });
  });
}