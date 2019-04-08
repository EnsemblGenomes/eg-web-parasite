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

# $Id: Transcript.pm,v 1.27 2014-01-15 10:36:13 jh15 Exp $

package EnsEMBL::Web::Configuration::Transcript;

use strict;
use Data::Dumper;

use base qw(EnsEMBL::Web::Configuration);

use previous qw(modify_tree);

sub modify_tree {
  my $self = shift;

  $self->PREV::modify_tree(@_);

  $self->delete_node('SupportingEvidence');
  $self->delete_node('Oligos');
  $self->delete_node('Variation');
  $self->delete_node('ProtVariations');
  $self->delete_node('UserAnnotation');
  $self->delete_node('History');
  $self->delete_node('ExternalRecords'); 
  $self->delete_node('PDB'); 
 
  if($self->hub->species_defs->EVA_TRACKS) {
    my $variation = $self->create_node('EVA', 'Variation', [],
      { availability => 0 }
    );
    $variation->append(
      $self->create_node('EVA_Table', 'Variation Table',
        [qw(eva_table EnsEMBL::Web::Component::Transcript::EVA_Table)]
      )
    );
  }
  
  my $summary = $self->get_node('Summary');
  $summary->set('components',
    [qw(
      image         EnsEMBL::Web::Component::Transcript::TranscriptImage
      wormbase      EnsEMBL::Web::Component::WormBaseLink
      trans_summary EnsEMBL::Web::Component::Transcript::TranscriptSummary
    )]
  );
  
  $self->create_node('Similarity', 'External References',
    [qw( similarity EnsEMBL::Web::Component::Transcript::SimilarityMatches )],
    { 'availability' => 'transcript has_similarity_matches', 'concise' => 'External References' }
  );
  
  my $cdna = $self->get_node('Sequence_cDNA');
  $cdna->set('availability', 'translation');
  
}

1;

