=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::Gene;

use previous qw(modify_tree);

sub modify_tree {
  my $self = shift;

  $self->PREV::modify_tree(@_);

  my $compara_menu = $self->get_node('Compara');
  $compara_menu->set('caption', "Comparative Genomics");

  $self->delete_node('Family');
  $self->delete_node('Gene_families');
  $self->delete_node('PanCompara');
  $self->delete_node('Alleles');
  $self->delete_node('Evidence');
  $self->delete_node('SecondaryStructure');
  $self->delete_node('Regulation');
  $self->delete_node('Expression');
  $self->delete_node('Compara_Alignments');
  $self->delete_node('SpeciesTree');
  $self->delete_node('Variation');
  $self->delete_node('StructuralVariation_Gene');
  $self->delete_node('ExternalData');
  $self->delete_node('UserAnnotation');
  $self->delete_node('History');
  $self->delete_node('Idhistory');
  $self->delete_node('Phenotype');
 
  my $summary = $self->get_node('Summary');
  $summary->set('components',
    [qw(
      gene_summary  EnsEMBL::Web::Component::Gene::GeneSummary
      wormbase      EnsEMBL::Web::Component::WormBaseLink
      navbar        EnsEMBL::Web::Component::ViewNav
      transcripts   EnsEMBL::Web::Component::Gene::TranscriptsImage
    )]
  );
  
}

1;
