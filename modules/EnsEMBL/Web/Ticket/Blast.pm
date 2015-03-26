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

package EnsEMBL::Web::Ticket::Blast;

use strict;
use warnings;

sub _process_user_input {
  ## @private
  ## Validates the inputs, then create set of parameters for each job, ready to be submitted
  ## Returns undefined if any of the parameters (other than sequences/species) are invalid (no specific message is returned since all validations were done at the frontend first - if input is still invalid, someone's just messing around)
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $params      = {};
  my $valid_chars = SEQUENCE_VALID_CHARS;

  # Validate Species
  my @species = $sd->tools_valid_species($hub->param('species'));
  return unless @species;

  # Source param depends upon the selected db type
  $hub->param('source', $hub->param('source_'.$hub->param('db_type')));

  # Validate Query Type, DB Type, Source Type and Search Type
  for (qw(query_type db_type source search_type)) {
    my $param_value = $params->{$_} = $hub->param($_);
    return unless $param_value && $object->get_param_value_caption($_, $param_value); #get_param_value_caption returns undef if value is invalid
  }

  # Process the extra configurations
  $params->{'configs'} = $self->_process_extra_configs($params->{'search_type'});
  return unless $params->{'configs'};

  # Process and validate input sequences
  my $sequences = [];
  for ($hub->param('sequence')) {

    next if ($_ // '') eq '';

    my @seq_lines = split /\R/, $_;
    my $fasta     = $seq_lines[0] =~ /^>/ ? [ shift @seq_lines ] : [ '>' ];
    my $sequence  = join '', @seq_lines;

    # Rebuild fasta with 60 chars column length
    push @$fasta, $1 while $sequence =~ m/(.{1,60})/g;

    push @$sequences, {
      'fasta'       => join("\n", @$fasta),
      'display_id'  => $fasta->[0] =~ s/^>\s*//r,
      'is_invalid'  => $sequence =~ m/^[$valid_chars]*$/
        ? (length $sequence <= MAX_SEQUENCE_LENGTH)
        ? 0
        : sprintf('Sequence contains more than %s characters', MAX_SEQUENCE_LENGTH)
        : sprintf('Sequence contains invalid characters (%s)', join('', ($sequence =~ m/[^$valid_chars]/g)))
    };
  }
  return unless @$sequences;

  # Create parameter sets for individual jobs to be submitted (submit one job per sequence per species)
  my ($blast_type, $search_method)  = $object->parse_search_type($params->{'search_type'});
  my $desc                          = $hub->param('description');
  my $source_types                  = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES');
  my $jobs                          = [];
  my $job_num                       = 0;

## ParaSite concat results: generate a string of database names then submit as one single job instead of one job per species
if($hub->param('species_select') eq 'concat') {
  my @blast_dbs;
  for my $species (@species) {
    push @blast_dbs, $sd->get_blast_datasource_filename($species, $blast_type, $params->{'source'});
  }
  for my $sequence (@$sequences) {
    my $summary = sprintf('%s genomes, %s (%s)', scalar(@blast_dbs), $search_method, $source_types->{$params->{'source'}});
    push @$jobs, [ {
      'job_number'  => ++$job_num,
      'job_desc'    => $desc || $sequence->{'display_id'} || $summary,
      'species'     => 'Multi',
      'assembly'    => 'Multi',
      'job_data'    => {
        'output_file' => 'blast.out',
        'sequence'    => {
          'input_file'  => 'input.fa',
          'is_invalid'  => $sequence->{'is_invalid'}
        },
        'summary'     => $summary,
        'source_file' => \@blast_dbs,   # Submit multiple database names into a single job
        %$params
      }
    }, {
      'input.fa'    => {
        'content'     => $sequence->{'fasta'}
      }
    } ];
  }
} else {
## ParaSite concat results

  for my $species (@species) {

    for my $sequence (@$sequences) {

      my $summary = sprintf('%s (%s)', $search_method, $source_types->{$params->{'source'}});

      push @$jobs, [ {
        'job_number'  => ++$job_num,
        'job_desc'    => $desc || $sequence->{'display_id'} || $summary,
        'species'     => $species,
        'assembly'    => $sd->get_config($species, 'ASSEMBLY_VERSION'),
        'job_data'    => {
          'output_file' => 'blast.out',
          'sequence'    => {
            'input_file'  => 'input.fa',
            'is_invalid'  => $sequence->{'is_invalid'}
          },
          'summary'     => $summary,
          'source_file' => $sd->get_blast_datasource_filename($species, $blast_type, $params->{'source'}),
          %$params
        }
      }, {
        'input.fa'    => {
          'content'     => $sequence->{'fasta'}
        }
      } ];
    }
  }
## ParaSite
}
##

  return $jobs;
}

1;
