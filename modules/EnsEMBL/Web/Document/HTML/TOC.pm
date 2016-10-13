package EnsEMBL::Web::Document::HTML::TOC;

use strict;

sub heading_html {
  my ($self,$dir,$title) = @_;

  return qq{<div class="plain-box"><h2 class="box-header">$title</h2>\n};
}

1;
