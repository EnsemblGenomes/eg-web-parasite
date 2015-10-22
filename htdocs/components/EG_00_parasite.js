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
      .css('width', '100%')
      .css('height', '100%')
      .css('position', 'fixed')
      .css('top', '0px')
      .css('bottom', '0px')
      .css('left', '0px')
      .css('right', '0px')
      .css('cursor', 'zoom-out')
      .click(function() {
        $(this).remove();
      })
      .append(
        $('<div></div>')
          .css('width', '100%')
          .css('height', '100%')
          .css('position', 'absolute')
          .css('background', '#000000')
          .css('opacity', '0.4')
          .css('z-index', '101')
        )
      .append(
        $('<div></div>')
          .css('height', '75%')
          .css('width', '75%')
          .css('position', 'relative')
          .css('text-align', 'center')
          .css('margin', '5% auto 5% auto')
          .css('opacity', '1')
          .css('z-index', '102')
          .css('background', '#FFFFFF')
          .css('border-radius', '20px')
          .append(
            $('<img></img>')
              .attr('class', 'image-large')
              .css('max-height', '95%')
              .css('max-width', '95%')
              .css('height', 'auto')
              .css('width', 'auto')
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

