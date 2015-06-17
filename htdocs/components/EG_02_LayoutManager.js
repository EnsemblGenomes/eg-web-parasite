Ensembl.LayoutManager.showCookieMessage = function() {
  var cookiesAccepted = Ensembl.cookie.get('cookies_ok');

  if (!cookiesAccepted) {
    $(['<div class="cookie-message hidden">',
      '<div></div>',
      '<p>We use cookies to enhance the usability of our website. If you continue, we\'ll assume that you are happy to receive all cookies.</p>',
      '<p><button>Don\'t show this again</button></p>',
      '<p>Read more about EMBL-EBI policies: <a href="http://www.ebi.ac.uk/about/cookie-control">Cookies</a> | <a href="http://www.ebi.ac.uk/about/privacy">Privacy</a>.</p>',
      '</div>'
    ].join(''))
      .appendTo(document.body).show().find('button,div').on('click', function (e) {
        Ensembl.cookie.set('cookies_ok', 'yes');
        $(this).parents('div').first().fadeOut(200);
    }).filter('div').helptip({content:"Don't show this again"});
    return true;
  }

  return false;
};

