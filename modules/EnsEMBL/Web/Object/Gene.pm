=head1 LICENSE

Copyright [2014-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Gene;

use strict;

sub gxa_check {
  my $self = shift;
  return unless $self->hub->species_defs->GXA;
  return 1;
}

sub get_homologue_alignments {
  my $self        = shift;
  my $compara_db  = shift || 'compara';
  my $type        = shift || 'ENSEMBL_ORTHOLOGUES';
  my $database    = $self->database($compara_db);
  my $hub         = $self->hub;
  my $msa;

  if ($database) {
    my $member  = $database->get_GeneMemberAdaptor->fetch_by_stable_id($self->Obj->stable_id);
    my $tree    = $database->get_GeneTreeAdaptor->fetch_default_for_Member($member);
    my @params  = ($member, $type);
    my $species = [];
## ParaSite: check the species is actually in compara
    my $genome_adaptor  = $database->get_adaptor('GenomeDB');
    foreach (grep { /species_/ } $hub->param) {
      (my $sp = $_) =~ s/species_//;
      my $g = $genome_adaptor->fetch_by_name_assembly($sp);
         $g = $genome_adaptor->fetch_by_registry_name($sp) unless $g;
      push @$species, $sp if $hub->param($_) eq 'yes' && $g;
    }
##
    push @params, $species if scalar @$species;
    $msa        = $tree->get_alignment_of_homologues(@params);
    $tree->release_tree;
  }
  return $msa;
}

1;

