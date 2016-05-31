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

  my $summary = $self->get_node('Summary');
  $summary->set('components',
    [qw(
      image         EnsEMBL::Web::Component::Transcript::TranscriptImage
      wormbase      EnsEMBL::Web::Component::WormBaseLink
      trans_summary EnsEMBL::Web::Component::Transcript::TranscriptSummary
    )]
  );
  
}

1;

