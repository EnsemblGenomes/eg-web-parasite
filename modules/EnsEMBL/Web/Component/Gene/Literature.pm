=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Component::Gene::Literature;
use strict;

# Change of query for PARASITE-439
sub get_gene_names {
  my $self   = shift;
  my $obj    = $self->object->Obj;
  my @names  = ($obj->display_id);

  if ($obj->can('display_xref')) {
    if (my $xref = $obj->display_xref) {
      push @names, $xref->display_id;
      push @names, @{$xref->get_all_synonyms};
    }
  }
  
  return \@names;
}


1;

