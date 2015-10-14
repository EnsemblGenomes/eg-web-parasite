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

sub get_result_urls {
  ## Gets url links for the result hit
  ## @param Job object
  ## @param Result object
  ## @return Hashref of keys as link types and values as hashrefs as accepted by hub->url (or arrayref of such hashrefs in case of genes)
  my ($self, $job, $result) = @_;

## ParaSite edit: get species from result as job may not be a single species
  my $species     = $result->result_data->{'species'};
## ParaSite
  my $job_data    = $job->job_data;
  my $source      = $job_data->{'source'};
  my $hit         = $result->result_data;
  my $url_param   = $self->create_url_param({'job_id' => $job->job_id, 'result_id' => $result->result_id});
  my $urls        = {};

  # Target url (only for sources other than genmoic seq)
  if ($source !~ /latestgp/i) {
    my $target = $self->get_target_object($hit, $source);
       $target = $target->transcript if $target->isa('Bio::EnsEMBL::Translation');

    my $param  = $target->isa('Bio::EnsEMBL::PredictionTranscript') ? 'pt' : 't';

    $urls->{'target'} = {
      'species' => $species,
      'type'    => 'Transcript',
      'action'  => $source =~/cdna|ncrna/i ? 'Summary' : 'ProteinSummary',
      $param    => $hit->{'tid'},
      'tl'      => $url_param
    };
  }

  # Genes url
  $urls->{'gene'} = [];
  for (@{$self->get_genes_for_hit($job, $result)}) {
    my $label = $_->display_xref;
    push @{$urls->{'gene'}}, {
      'species' => $species,
      'type'    => 'Gene',
      'action'  => 'Summary',
      'g'       => $_->stable_id,
      'tl'      => $url_param,
      'label'   => $label ? $label->display_id : $_->stable_id
    };
  }

  # Location url
  my $start   = $hit->{'gstart'} < $hit->{'gend'} ? $hit->{'gstart'} : $hit->{'gend'};
  my $end     = $hit->{'gstart'} > $hit->{'gend'} ? $hit->{'gstart'} : $hit->{'gend'};
  my $length  = $end - $start;

  # add 5% padding on both sides
  $start  = int($start - $length * 0.05);
  $start  = 1 if $start < 1;
  $end    = int($end + $length * 0.05);

  $urls->{'location'} = {
    '__clear'           => 1,
    'species'           => $species,
    'type'              => 'Location',
    'action'            => 'View',
    'r'                 => sprintf('%s:%s-%s', $hit->{'gid'}, $start, $end),
    'tl'                => $url_param
  };

  # Alignment url
  $urls->{'alignment'} = {
    'species'   => $species,
    'type'      => 'Tools',
    'action'    => 'Blast',
    'function'  => $self->get_alignment_component_name_for_job($job),
    'tl'        => $url_param
  };

  # Query sequence url
  $urls->{'query_sequence'} = {
    'species'   => $species,
    'type'      => 'Tools',
    'action'    => 'Blast',
    'function'  => 'QuerySeq',
    'tl'        => $url_param
  };

  # Genomic sequence url
  $urls->{'genomic_sequence'} = {
    'species'   => $species,
    'type'      => 'Tools',
    'action'    => 'Blast',
    'function'  => 'GenomicSeq',
    'tl'        => $url_param
  };

  return $urls;
}

sub get_genes_for_hit {
  ## Returns the gene objects linked to a blast hit
  ## @param Job object
  ## @param Blast result object
  my ($self, $job, $result) = @_;

  my $hit = $result->result_data;
  my @genes;

  if ($hit->{'genes'}) {

    if (@{$hit->{'genes'}}) {
## ParaSite: Change from job species to hit species
      my $adaptor = $self->hub->get_adaptor("get_GeneAdaptor", 'core', $hit->{'species'});
##
      @genes = map { $adaptor->fetch_by_stable_id($_) } @{$hit->{'genes'}};
    }

  } else {
    my $source = $job->job_data->{'source'};

    if ($source =~ /latestgp/i) {
      @genes = @{$self->get_hit_genomic_slice($hit)->get_all_Genes};

    } else {
      my $target = $self->get_target_object($hit, $source);
         $target = $target->transcript if $target->isa('Bio::EnsEMBL::Translation');

      push @genes, $target->get_Gene || () unless $target->isa('Bio::EnsEMBL::PredictionTranscript');
    }

    # cache it in the db
    $hit->{'genes'} = [ map $_->stable_id, @genes ];
    $result->save;
  }

  return \@genes;
}

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self  = shift;
  my $hub   = $self->hub;
  my $jobs  = $self->get_requested_job || $self->get_requested_ticket;
     $jobs  = $jobs ? ref($jobs) =~ /Ticket/ ? $jobs->job : [ $jobs ] : [];

  my @jobs_data;

  if (@$jobs) {

    my %config_fields = map { @$_ } values %{{ @{CONFIGURATION_FIELDS()} }};

    for (@$jobs) {
      my $job_data = $_->job_data->raw;
## ParaSite: species may be stored as an array in one single job
      my @source_species = $job_data->{'source_species'} ? @{$job_data->{'source_species'}} : $_->species;
      delete $job_data->{$_} for qw(source_file output_file);
      foreach my $species (@source_species) {
        my $job_data = $_->job_data->raw;
        delete $job_data->{$_} for qw(source_file output_file);
        $job_data->{'species'}  = {key => lc($species), title => $hub->species_defs->species_label($species)};
        $job_data->{'sequence'} = $self->get_input_sequence_for_job($_);
        for (keys %{$job_data->{'configs'}}) {
          $job_data->{'configs'}{$_} = { reverse %{$config_fields{$_}{'commandline_values'}} }->{ $job_data->{'configs'}{$_} } if exists $config_fields{$_}{'commandline_values'};
        }
        push @jobs_data, $job_data;
      }
##
    }
  }

  return \@jobs_data;
}

sub handle_download {
  ## Method reached by url ensembl.org/Download/Blast/
  my ($self, $r) = @_;
## ParaSite: method modified to permit downloading of multiple jobs in one file
  my $content;
  my $filename;
  
  if($self->create_url_param =~ /-all/) {
    my $ticket = $self->get_requested_ticket;
    $filename = $ticket->ticket_name;
    foreach my $job ($ticket->job) {
      $content .= sprintf("============= Job %s =============\n\n", $job->job_desc);
      my $result_file = sprintf '%s/%s', $job->job_dir, $job->job_data->{'output_file'};
      $content .= join '', map { s/\R/\r\n/r } file_get_contents($result_file);
    }
  } else {
    my $job = $self->get_requested_job;
    $filename = $self->create_url_param;
    my $result_file = sprintf '%s/%s', $job->job_dir, $job->job_data->{'output_file'};
    $content = join '', map { s/\R/\r\n/r } file_get_contents($result_file);  
  }

  $r->headers_out->add('Content-Type'         => 'text/plain');
  $r->headers_out->add('Content-Length'       => length $content);
  $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s.blast.txt', $filename);
## ParaSite

  print $content;
}

1;
