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

package EnsEMBL::Web::Component::Gene::GeneSeq;

use strict;

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Gene);

sub section_title {
  return 'Gene Sequence';
}

sub initialize {
  my ($self, $slice, $start, $end, $adorn) = @_;
  my $hub    = $self->hub;
  my $object = $self->get_object;

  my $config = {
    display_width   => $hub->param('display_width') || 60,
    site_type       => $hub->species_defs->ENSEMBL_SITETYPE,
    gene_name       => $object->Obj->can('external_name') && $object->Obj->external_name ? $object->Obj->external_name : $object->stable_id,
    species         => $hub->species,
    sub_slice_start => $start,
    sub_slice_end   => $end,
    ambiguity       => 1,
  };

  for (qw(exon_display exon_ori snp_display line_numbering title_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }

  $config->{'exon_features'} = $object->Obj->get_all_Exons;
  $config->{'slices'}        = [{ slice => $slice, name => $config->{'species'} }];
  $config->{'end_number'}    = $config->{'number'} = 1 if $config->{'line_numbering'};

  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config,$adorn);

  $self->markup_exons($sequence, $markup, $config)     if $config->{'exon_display'};
  if($adorn ne 'none') {
    $self->markup_variation($sequence, $markup, $config) if $config->{'snp_display'};
  }
  $self->markup_line_numbers($sequence, $config)       if $config->{'line_numbering'};

  return ($sequence, $config);
}

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
