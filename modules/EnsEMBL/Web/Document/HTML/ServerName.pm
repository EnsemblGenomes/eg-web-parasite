package EnsEMBL::Web::Document::HTML::ServerName;

use Sys::Hostname;

sub render {
  return hostname;
}

1;
