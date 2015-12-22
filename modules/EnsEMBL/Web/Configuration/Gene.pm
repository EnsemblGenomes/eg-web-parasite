=head1 LICENSE

Copyright [2009-2015] EMBL-European Bioinformatics Institute

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

sub populate_tree {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;

  $self->create_node('Summary', 'Gene in Detail',
    [qw(
      singlepage    EnsEMBL::Web::Component::SinglePage
      wormbase      EnsEMBL::Web::Component::WormBaseLink
      navbar        EnsEMBL::Web::Component::ViewNav
      transcripts   EnsEMBL::Web::Component::Gene::TranscriptsImage
      splice_image  EnsEMBL::Web::Component::Gene::SpliceImage
      gene_seq      EnsEMBL::Web::Component::Gene::GeneSeq
      go            EnsEMBL::Web::Component::Gene::Go
      orthologues   EnsEMBL::Web::Component::Gene::ComparaOrthologs
      paralogues    EnsEMBL::Web::Component::Gene::ComparaParalogs
      matches       EnsEMBL::Web::Component::Gene::SimilarityMatches
    )],
    { 'availability' => 'gene' }
  );
  
  $self->create_node('Compara_Tree', 'Gene tree',
    [qw( image EnsEMBL::Web::Component::Gene::ComparaTree )],
    { 'availability' => 'gene database:compara core has_gene_tree' }
  );
  
  ### TODO: Only add the elements above if these are actually available - will need a rewrite of this sub
 
}

sub modify_tree {
  my $self = shift;

#  my $compara_menu = $self->get_node('Compara');
#  $compara_menu->set('caption', "Comparative Genomics");

}

1;
