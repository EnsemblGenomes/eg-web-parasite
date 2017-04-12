package EnsEMBL::Web::Component::Tools::InputForm;

sub current_species {
  ## Gets the current species name for which the form should be displayed
  ## @note Avoid overriding this in child class
  ## @return String species name
  my $self = shift;

  if (!$self->{'_current_species'}) {
    my $hub     = $self->hub;
    my $species = $hub->species;
## ParaSite: removed the Ensembl favourite/default species stuff from here.  We actually want Multi.

    $self->{'_current_species'} = $species;
  }

  return $self->{'_current_species'};
}

1;

