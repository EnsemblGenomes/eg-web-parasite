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

package EnsEMBL::Web::Component::Tools::Blast::ResultsTable;

### Component to display a table for all the results of a single blast job

use strict;
use warnings;

sub table_columns {
  ## Returns a list of columns for the results table
  ## @param Job object
  ## @return Arrayref of column as expected by new_table method
  my ($self, $job) = @_;

  my $glossary = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($self->hub)->fetch_glossary_lookup;

  return [ $job->job_data->{'source'} =~/latestgp/i ? (
## ParaSite
    { 'key' => 'species', 'title'=> 'Genome',               'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genome (BLAST Results)'}                     },
## 
    { 'key' => 'tid',     'title'=> 'Genomic Location',     'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genomic Location (BLAST Results)'}           },
    { 'key' => 'gene',    'title'=> 'Overlapping Gene(s)',  'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Overlapping Genes (BLAST Results)'}          },
    { 'key' => 'tori',    'title'=> 'Orientation',          'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Orientation (BLAST Results for genomic)'}    }
  ) : (
## ParaSite
    { 'key' => 'species', 'title'=> 'Genome',               'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genome (BLAST Results)'}                     },
## 
    { 'key' => 'tid',     'title'=> 'Subject name',         'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Subject name (BLAST Results)'}               },
## EG    
    { 'key' => 'desc',    'title'=> 'Subject description',  'align' => 'left',  'sort' => 'string'  },    
## 
    { 'key' => 'gene',    'title'=> 'Gene hit',             'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Gene hit (BLAST Results)'}                   },
    { 'key' => 'tstart',  'title'=> 'Subject start',        'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Subject start (BLAST Results)'}              },
    { 'key' => 'tend',    'title'=> 'Subject end',          'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Subject end (BLAST Results)'}                },
    { 'key' => 'tori',    'title'=> 'Subject ori',          'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Subject ori (BLAST Results)'}                },
    { 'key' => 'gid',     'title'=> 'Genomic Location',     'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Genomic Location (BLAST Results)'}           },
    { 'key' => 'gori',    'title'=> 'Orientation',          'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Orientation (BLAST Results for cDNA/protein)'}}
  ), ( 
    { 'key' => 'qid',     'title'=> 'Query name',           'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Query name (BLAST Results)'}, 'hidden' => 1  },  
    { 'key' => 'qstart',  'title'=> 'Query start',          'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Query start (BLAST Results)'}                },
    { 'key' => 'qend',    'title'=> 'Query end',            'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Query end (BLAST Results)'}                  },
    { 'key' => 'qori',    'title'=> 'Query ori',            'align' => 'left',  'sort' => 'string',         'help' => $glossary->{'Query ori (BLAST Results)'},  'hidden' => 1  },
    { 'key' => 'len',     'title'=> 'Length',               'align' => 'left',  'sort' => 'numeric_hidden', 'help' => $glossary->{'Length (BLAST Results)'}                     },
    { 'key' => 'score',   'title'=> 'Score',                'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'Score (BLAST Results)'}                      },
    { 'key' => 'evalue',  'title'=> 'E-val',                'align' => 'left',  'sort' => 'numeric',        'help' => $glossary->{'E-val (BLAST Results)'}                      },
    { 'key' => 'pident',  'title'=> '%ID',                  'align' => 'left',  'sort' => 'numeric_hidden', 'help' => $glossary->{'%ID (BLAST Results)'}                        }
  ) ];
}

sub table_options {
  ## Returns options for rendering the results table
  ## @param Job object
  ## @return Hashref of table options as expected by new_table method
  my ($self, $job) = @_;
  return {
    'id'          => sprintf('blast_results%s', $job->job_data->{'source'} =~ /latestgp/i ? '_1' : '_2'), # keep different session record for DataTable when saving sorting, hidden cols etc
    'data_table'  => 1,
    'sorting'     => ['score desc'],
## EG  & ParaSite         
    'hidden_columns' => $job->job_data->{'source'} =~/latestgp/i ? [3, 4, 5, 6] : [2, 4, 5, 6, 7, 8, 11] 
##        
  };
}

sub table_row {
  ## Returns one row per BLAST result to be added to the results table
  my ($self, $job, $result) = @_;

  my $result_id     = $result->result_id;
  my $result_row    = $result->result_data->raw;
  my $url_param     = $self->object->create_url_param({'result_id' => $result_id});
  my $urls          = $self->get_result_links($job, $result);

  $result_row->{'options'} = {'class' => "hsp_$result_id"};
  
## ParaSite: prettify the genome project name for multi-species results
  my $hub = $self->hub;
  my $sd  = $hub->species_defs;
  $result_row->{'species'} = sprintf('%s (%s%s)', $sd->get_config($result_row->{'species'}, 'SPECIES_SCIENTIFIC_NAME'), $sd->get_config($result_row->{'species'}, 'SPECIES_BIOPROJECT'), $sd->get_config($result_row->{'species'}, 'SPECIES_STRAIN') ? ' - ' . $sd->get_config($result_row->{'species'}, 'SPECIES_STRAIN') : '');
##

  # orientation columns
  $result_row->{$_} = $result_row->{$_} == 1 ? 'Forward' : 'Reverse' for grep m/ori$/, keys %$result_row;

  # columns with links
  $result_row->{'gid'}    = $result_row->{'tid'} = qq($urls->{'location'}&nbsp;$urls->{'genomic_sequence'});
  $result_row->{'tid'}    = $urls->{'target'} unless $job->job_data->{'source'} =~ /latestgp/i;
  $result_row->{'gene'}   = $urls->{'gene'};
  $result_row->{'len'}    = sprintf('<span>%s</span>&nbsp;%s', $result_row->{'len'}, $urls->{'query_sequence'});
  $result_row->{'pident'} = sprintf('<span>%s</span>&nbsp;%s', $result_row->{'pident'}, $urls->{'alignment'});

  return $result_row;
}

sub get_result_links {
  ## Gets the links for all required table columns
  my ($self, $job, $result) = @_;

  my $hit   = $result->result_data;
  my $hub   = $self->hub;
  my $urls  = $self->object->get_result_urls($job, $result);
  my $sp    = $hit->{'species'};

  return {
    'gene'              => join(', ', map { sprintf '<a href="%2$s">%1$s</a>', delete $_->{'label'}, $hub->url($_) } @{$urls->{'gene'}}) || '',
    'target'            => $urls->{'target'} ? sprintf('<a href="%s">%s</a>', $hub->url($urls->{'target'}), $hit->{'tid'}) : '',
    'location'          => sprintf('<a href="%s" class="_ht" title="Region in Detail">%s:%s-%s</a>', $hub->url($urls->{'location'}), $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}),
    'genomic_sequence'  => sprintf('<a href="%s" class="small _ht" title="View Genomic Sequence">[Sequence]</a>', $hub->url($urls->{'genomic_sequence'})),
    'query_sequence'    => sprintf('<a href="%s" class="small _ht" title="View Query Sequence">[Sequence]</a>', $hub->url($urls->{'query_sequence'})),
    'alignment'         => sprintf('<a href="%s" class="small _ht" title="View Alignment">[Alignment]</a>', $hub->url($urls->{'alignment'}))
  };
}

1;
