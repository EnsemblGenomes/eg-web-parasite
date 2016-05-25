package EnsEMBL::Web::Component::Location::Summary;

use strict;
use previous qw(content);

sub content {
  my $self = shift;
  return if $self->hub->action eq 'EVA_Variant';
  $self->PREV::content(@_);
}

1;

