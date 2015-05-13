Ensembl.Panel.SearchBox = Ensembl.Panel.extend({
  init: function() {
    this.base();
    $("#se_q").autocomplete({
      source: function(request, response) {
        $.ajax({
          url: "/Multi/Ajax/search_autocomplete",
          dataType: "json",
          data: {
            term: request.term,
            format: "json"
          },
          success: function(data) {
              response($.map(data, function(item) {
                return {
                  label: item,
                  value: item
                }
              }));
          }
        });
      },
      minLength: 3,
      select: function(event, ui) {
        $("#se_q").val(ui.item.value);
        $("#searchForm").submit();
      }
    })
    .data("ui-autocomplete")._renderItem = function (ul, item) {
      var regex = new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(this.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi");
      item.label = item.label.replace(regex, "<strong>$1</strong>");
      return $("<li></li>").data("ui-autocomplete-item", item).append("<a>" + item.label + "</a>").appendTo(ul);
    };
  }
});
