(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

// Tell Google who we are    
ga('create', 'UA-24717231-5', 'auto');
// Trigger a pageview event
ga('send', 'pageview');

// Some listeners to track events
$('.data').click(function() {
  ga('send', 'event', 'user_upload', 'left-menu-btn', 'click on left menu add your data button');
});
$('.config').click(function() {
  ga('send', 'event', 'configure_page', 'left-menu-btn', 'click on left menu configure this page button');
});
$('.export').click(function() {
  ga('send', 'event', 'export_data', 'left-menu-btn', 'click on left menu export data button');
});


