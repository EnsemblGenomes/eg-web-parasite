$('.home-button').hover(function() {
  $(this).addClass('home-button-hover'); 
}, function() {
  $(this).removeClass('home-button-hover');
});

$('.image-expand').click(function() {
  var url = $(this).attr('src');
  $('body').append(
    $('<div></div>')
      .attr('class', 'image-popup')
      .click(function() {
        $(this).remove();
      })
      .append(
        $('<div></div>')
          .attr('class', 'image-popup-bg')
        )
      .append(
        $('<div></div>')
          .attr('class', 'image-popup-fg')
          .append(
            $('<img></img>')
              .attr('class', 'image-large')
              .attr('src', url)
          )
      )
    ).hide().fadeIn('fast');
});

$(document).keyup(function(e) {
  if(e.keyCode == 27) {
    $('.image-popup').remove();
  }
});

