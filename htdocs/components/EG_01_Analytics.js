(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

// Tell Google who we are    
ga('create', 'UA-24717231-5', 'auto');
// Trigger a pageview event
ga('send', 'pageview');

$(document).ready(function() { // Add the event listeners when the page loads
  initAnalyticsListener();
});

$(document).ajaxComplete(function() { // Apply the listeners again each time an AJAX element has completed loading
  initAnalyticsListener();
});

// This function loads the listeners to track events
function initAnalyticsListener() {

  //Homepage
  $('.home-button').click(function() {
    ga('send', 'event', 'homepage', 'icon-buttons-click', 'click on large homepage buttons');
  });
  $('.expanding-header').click(function() {
    ga('send', 'event', 'homepage', 'expanding-header-click', 'click on homepage navigation header');
  });
  $('.species-link').click(function() {
    ga('send', 'event', 'homepage', 'expanding-species-click', 'click on species link within homepage navigation');
  });
  $('.blog-link').click(function() {
    ga('send', 'event', 'homepage', 'blog-link-click', 'click on link to blog');
  });

  // Header
  $('.tools_holder .tools').click(function() {
    ga('send', 'event', 'header', 'tools', 'click on a tool link in the header');
  });
  $('.search-query').keypress(function() {
    ga('send', 'event', 'header', 'search-box-keypress', 'typing in header search box');
  });

  // Footer
  $('.footer a').click(function() {
    ga('send', 'event', 'footer', 'link-click', 'click on some link in the footer');
  });

  // Custom data tracks (aka user upload)
  $('.data').click(function() {
    ga('send', 'event', 'user_upload', 'left-menu-btn', 'click on left menu add your data button');
  });
  $('#SelectFile form').submit(function() {
    var fileFormat = $(this).find('select[name="format"]').val();
    ga('send', 'event', 'user_upload', 'submit-' + fileFormat, 'addition of custom track with file format ' + fileFormat);
  });

  // Configure this page
  $('.config').click(function() {
    ga('send', 'event', 'configure_page', 'left-menu-btn', 'click on left menu configure this page button');
  });

  // Data export
  $('.export').click(function() {
    ga('send', 'event', 'export_data', 'left-menu-btn', 'click on left menu export data button');
  });

  // Gene trees
  $('.imagemap').click(function() {
    ga('send', 'event', 'genetree', 'click', 'user has clicked on gene tree imagemap');
  });
  $('.update_panel').click(function() {
    ga('send', 'event', 'genetree', 'update', 'user has expanded or collapsed the gene tree');
  });
  $('.update_genetree').click(function() {
    ga('send', 'event', 'genetree', 'ontology-highlight', 'user has clicked a radio button in the GO term highlighting table');
  });

  // BLAST
  $('.blast-form').submit(function() {
    ga('send', 'event', 'blast', 'submit', 'submission of blast form');
  });
  $('.edit_icon').click(function() {
    ga('send', 'event', 'blast', 'edit', 'click button to edit blast job');
  });
  $('.delete_icon').submit(function() {
    ga('send', 'event', 'blast', 'delete', 'click button to delete blast job');
  });

}

