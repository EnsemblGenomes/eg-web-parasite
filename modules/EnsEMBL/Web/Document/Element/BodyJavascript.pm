package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Document::Element);

sub init {
  my $self          = shift;
  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my $js_groups     = $species_defs->get_config('ENSEMBL_JSCSS_FILES')->{'js'};

  for (@$js_groups) {
## ParaSite: do not check this condition
#    next unless $_->condition($hub);
##

    if (($hub->param('debug') || '') eq 'js' || $species_defs->ENSEMBL_DEBUG_JS) {
      $self->add_script($_->url_path) for @{$_->files};
    } else {
      $self->add_script($_->minified_url_path);
    }
  }
}

1;
