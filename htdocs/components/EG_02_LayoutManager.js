Ensembl.LayoutManager.showCookieMessage = function() {
  var cookiesAccepted = Ensembl.cookie.get('cookies_ok');

  if (!cookiesAccepted) {
    $(['<div class="cookie-message hidden">',
      '<p class="msg">We use cookies to enhance the usability of our website. If you continue, we\'ll assume that you are happy to receive all cookies.&nbsp;',
      '<span class="more-info">Read more about EMBL-EBI policies: <a href="http://www.ebi.ac.uk/about/cookie-control">Cookies</a> | <a href="http://www.ebi.ac.uk/about/privacy">Privacy</a>.</span>',
      '</p>',
      '<span class="close">x</span>',
      '</div>'
    ].join(''))
      .appendTo(document.body).show().find('span.close').on('click', function (e) {
        Ensembl.cookie.set('cookies_ok', 'yes');
        $(this).parents('div').first().fadeOut(200);
    });
    return true;
  }

  return false;
};

