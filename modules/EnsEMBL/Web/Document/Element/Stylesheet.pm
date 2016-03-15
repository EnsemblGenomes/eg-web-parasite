package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Document::Element);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

sub init {
  my $self          = shift;
  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my @css_groups    = @{$species_defs->get_config('ENSEMBL_JSCSS_FILES')->{'css'}||[]};

  push @css_groups,@{$species_defs->get_config('ENSEMBL_JSCSS_FILES')->{'image'}||[]};
  for (@css_groups) {
## ParaSite: do not check this condition
#    next unless $_->condition($hub);
##

    if((($hub->param('debug') || '') eq 'css' || $species_defs->ENSEMBL_DEBUG_CSS) and @{$_->files}) {
      $self->add_sheet(sprintf '/CSS?%s', $_->url_path) for @{$_->files};
    } else {
      $self->add_sheet($_->minified_url_path);
    }
  }
}

1;
