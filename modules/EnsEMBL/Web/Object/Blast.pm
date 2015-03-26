=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Blast;

## The aim is to create an object which can be updated to
## use a different queuing mechanism, without any need to
## change the user interface. Where possible, therefore,
## public methods should accept the same arguments and
## return the same values

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use EnsEMBL::Web::BlastConstants qw(CONFIGURATION_FIELDS);

use parent qw(EnsEMBL::Web::Object::Tools);

sub get_result_url {
  ## Gets required url links for the result hit
  ## @param Link type (either one of these: target, location, alignment, query_sequence, genomic_sequence)
  ## @param Job object
  ## @param Result object
  ## @return Hashref as accepted by hub->url
  my ($self, $link_type, $job, $result) = @_;

## ParaSite edit: get species from result as job may not be a single species
  my $species     = $result->result_data->{'species'};
## ParaSite
  my $job_data    = $job->job_data;
  my $result_data = $result->result_data;
  my $url_param   = $self->create_url_param({'job_id' => $job->job_id, 'result_id' => $result->result_id});

  if ($link_type eq 'target') {

    my ($param, $gene, $gene_url, $gene_display);

    my $source  = $job_data->{'source'};
    my $target  = $self->get_target_object($result_data, $source);

    if ($target->isa('Bio::EnsEMBL::Translation')) {
      $param  = 'p';
      $target = $target->transcript;
    }

    if ($target->isa('Bio::EnsEMBL::PredictionTranscript')) {
      $param  = 'pt';
    } else { # Bio::EnsEMBL::Transcript
      $param  = 't';
      $gene   = $target->get_Gene;
    }

    if ($gene) {
      $gene_url = {
        'species' => $species,
        'type'    => 'Gene',
        'action'  => 'Summary',
        'g'       => $gene->stable_id,
        'tl'      => $url_param
      };
      $gene_display = $gene->display_xref;
      $gene_display = $gene_display ? $gene_display->display_id : $gene->stable_id;
    }

    my $transcript_url = {
      'species' => $species,
      'type'    => 'Transcript',
      'action'  => $source =~/cdna|ncrna/i ? 'Summary' : 'ProteinSummary',
      $param    => $result_data->{'tid'},
      'tl'      => $url_param
    };

    return wantarray ? ($transcript_url, $gene_url, $gene_display) : $transcript_url;

  } elsif ($link_type eq 'location') {

    my $start   = $result_data->{'gstart'} < $result_data->{'gend'} ? $result_data->{'gstart'} : $result_data->{'gend'};
    my $end     = $result_data->{'gstart'} > $result_data->{'gend'} ? $result_data->{'gstart'} : $result_data->{'gend'};
    my $length  = $end - $start;
    my $p_track = $self->parse_search_type($job->job_data->{'search_type'}, 'search_method') ne 'BLASTN' ? ',codon_seq=normal' : ''; # show translated track for any seach type other than dna vs dna

    # Add 5% padding on both sides
    $start  = int($start - $length * 0.05);
    $start  = 1 if $start < 1;
    $end    = int($end + $length * 0.05);

    return {
      '__clear'           => 1,
      'species'           => $species,
      'type'              => 'Location',
      'action'            => 'View',
      'r'                 => sprintf('%s:%s-%s', $result_data->{'gid'}, $start, $end),
      'contigviewbottom'  => "blast=normal$p_track",
      'tl'                => $url_param
    };

  } elsif ($link_type eq 'alignment') {

    return {
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => $self->get_alignment_component_name_for_job($job),
      'tl'        => $url_param
    };

  } elsif ($link_type eq 'query_sequence') {

    return {
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => 'QuerySeq',
      'tl'        => $url_param
    };

  } elsif ($link_type eq 'genomic_sequence') {

    return {
      'species'   => $species,
      'type'      => 'Tools',
      'action'    => 'Blast',
      'function'  => 'GenomicSeq',
      'tl'        => $url_param
    };
  }
}


1;
