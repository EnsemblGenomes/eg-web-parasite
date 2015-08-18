=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

# $Id: Gene.pm,v 1.29 2013-12-06 12:09:01 nl2 Exp $

package EnsEMBL::Web::Object::Gene;

use strict;
use Bio::EnsEMBL::Compara::Homology;

sub get_homology_matches_single_species {
  my ($self, $homology_source, $species, $query_member, $compara_db) = @_;

  my $database = $self->database($compara_db || 'compara');
  my $query_member   = $database->get_GeneMemberAdaptor->fetch_by_stable_id($query_member);

  return unless defined $query_member;

  my $orth_list = $database->get_HomologyAdaptor->fetch_all_by_Member_paired_species($query_member, $species, [$homology_source]);

  return $orth_list;
}

1;
