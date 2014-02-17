ForgePost.PAGES["faq/index"] = function() {
    var scope = $("#faq_index");

    function toggle_faq(id, fast) {
        scope.find(".faq").slideUp("fast");
        scope.find("h4 .toggle").text("[+]");

        if( scope.find(".faq-" + id + ":visible").length == 0 ) {
            var h4 = scope.find("#faq-" + id);
            h4.find(".toggle").text("[-]");

            if( fast ) {
                scope.find(".faq-" + id).show();
            } else {
                scope.find(".faq-" + id).slideDown("fast");
            }

            window.location.hash = id;
        }
    }

    var id = parseInt(window.location.hash.replace("#", ""));
    if( $.isNumeric(id) && scope.find("#faq-" + id).length == 1 ) {
        toggle_faq(id, true);
    }

    scope.find("h4").click(function(event) {
        toggle_faq($(this).data("id"), false);
    });
}