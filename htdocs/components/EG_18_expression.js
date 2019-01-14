$(".round-box .expandable").click(function() {
	$(this).children().toggle();
        $(this).next().slideToggle();
});
