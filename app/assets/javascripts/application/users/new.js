ForgePost.PAGES["users/new"] = function() {
  var scope = $("#users_new");
  scope.find("form").submit(function(event) {
    event.preventDefault();

    $(this).find("input[type='submit']").button("loading");

    var data = {};
    data.email = $.trim($("#user_email").val());
    data.password = $.trim($("#user_password").val());
    data.password_confirmation = $.trim($("#user_password_confirmation").val());

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