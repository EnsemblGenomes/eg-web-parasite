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

package EnsEMBL::Web::Component::Gene::GeneSeq;

use strict;

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Gene);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $slice     = $self->object->slice;
  my $length    = $slice->length;
  my $species   = $hub->species;
  my $type      = $hub->type;
  my $site_type = $hub->species_defs->ENSEMBL_SITETYPE;
  my $html      = '';

  if ($length >= $self->{'subslice_length'}) {
    $html .= '<div class="_adornment_key adornment-key"></div>';
    $html .= $self->chunked_content($length, $self->{'subslice_length'}, { length => $length, name => $slice->name });
  } else {
    $html .= '<div class="_adornment_key adornment-key"></div>';
    $html .= $self->content_sub_slice($slice); # Direct call if the sequence length is short enough
  }

  $html .= $self->_info('Sequence markup', qq{
    <p>
      $site_type has a number of sequence markup pages on the site. You can view the exon/intron structure
      of individual transcripts by selecting the transcript name in the table above, then clicking
      Exons in the left hand menu. Alternatively you can see the sequence of the transcript along with its
      protein translation and variation features by selecting the transcript followed by Sequence &gt; cDNA.
    </p>
    <p>
      This view and the transcript based sequence views are configurable by clicking on the "Configure this page"
      link in the left hand menu
    </p>
  });

  return $html;
}

1;
