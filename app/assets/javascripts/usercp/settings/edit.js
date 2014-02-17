ForgePost.PAGES["usercp/settings/edit"] = function() {
    var scope = $("#usercp_settings_edit form");
    scope.submit(function(event) {
        event.preventDefault();

        $(this).find("input[type='submit']").button("loading");

        var data = {};
        $(this).find(".control-group").find("input, textarea, select").each(function() {
            var input = $(this);
            if( !input.attr("name") ) return;
            var name = input.attr("name").match(/(\[.+\])/)[1].replace(/\[|\]/g, "");
            data[name] = input.val();
        });

        $.ajax($(this).attr("action"), {
            type: $(this).find("input[name='_method']").val() || "POST",
            data: data,
            error: function(xhr) {
                scope.find("input[type='submit']").button("reset");
                ForgePost.Helpers.Errors.handle_errors(scope, xhr);
            },
            success: function() {
                window.location = "/usercp/cards";
            }
        });
    });
}