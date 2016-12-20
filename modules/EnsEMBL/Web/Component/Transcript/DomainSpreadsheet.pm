package EnsEMBL::Web::Component::Transcript::DomainSpreadsheet;

use strict;
use previous qw(content);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $translation = $object->translation_object;

  return $self->non_coding_error unless $translation;
  
## ParaSite: don't display the ChEMBL hits in this table
  delete $object->table_info($object->get_db, 'protein_feature')->{'analyses'}->{'chembl'} if $object->table_info($object->get_db, 'protein_feature')->{'analyses'}->{'chembl'};
##

  $self->PREV::content;
}

1;
