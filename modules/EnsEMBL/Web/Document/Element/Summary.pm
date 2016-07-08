package EnsEMBL::Web::Document::Element::Summary;

use strict;
use previous qw(init);

sub init {
  my $self        = shift;
  my $hub         = $self->hub;
  return if $hub->type eq 'Location' && $hub->action eq 'EVA_Variant';
  $self->PREV::init(@_);
}

1;
