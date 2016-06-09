package EnsEMBL::Web::Object::Gene;

use strict;

sub gxa_check {
  my $self = shift;
  return unless $self->hub->species_defs->GXA;
  return 1;
}

1;

