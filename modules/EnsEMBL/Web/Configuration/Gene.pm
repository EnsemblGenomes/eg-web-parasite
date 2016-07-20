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
  $compara_menu->set('caption', "Comparative genomics");

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

  my $transcriptomic_menu = $self->create_submenu('Transcriptomic', 'Transcriptomic data', {'availability' => 'gene has_gxa', 'hide_if_unavailable' => 1});
  $transcriptomic_menu->append($self->create_subnode('ExpressionAtlas', 'Gene expression',
    [qw( atlas EnsEMBL::Web::Component::Gene::ExpressionAtlas )],
    { 'availability'  => 'gene has_gxa', 'hide_if_unavailable' => 1 }
  ));

  my $comparison = $self->get_node('TranscriptComparison');
  $comparison->set('hide_if_unavailable', 1);
 
  if($self->hub->species_defs->EVA_TRACKS) {
    my $variation = $self->create_node('EVA', 'Variation', [],
      { availability => 1 }
    );
    $variation->append(
      $self->create_node('EVA_Table', 'Variation Table',
        [qw(eva_table EnsEMBL::Web::Component::Gene::EVA_Table)]
      )
    );
    $variation->append(
      $self->create_node('EVA_Image', 'Variation Image',
        [qw(eva_image EnsEMBL::Web::Component::Gene::EVA_Image)]
      )
    );
  }

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
