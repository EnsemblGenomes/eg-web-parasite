package EnsEMBL::Web::Form::Element::SpeciesDropdown;

use strict;
use warnings;

use EnsEMBL::Web::SpeciesDefs;

use base qw(EnsEMBL::Web::Form::Element::Filterable);

sub configure {
  ## @overrrides
  my ($self, $params) = @_;

  my $sd = EnsEMBL::Web::SpeciesDefs->new;

  $self->SUPER::configure($params);

  $self->remove_attribute('class', '_fd');
  $self->set_attribute('class', '_sdd');

## ParaSite: we don't have species images, so removed the species_tag class from being assigned here
  
}

1;

