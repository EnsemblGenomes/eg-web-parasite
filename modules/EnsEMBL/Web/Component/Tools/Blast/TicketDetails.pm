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

package EnsEMBL::Web::Component::Tools::Blast::TicketDetails;

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @params Extra params as required by get_job_summary method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job) = splice @_, 0, 2;

  my $object      = $self->object;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $job_data    = $job->job_data;
  my $job_num     = $job->job_number;
  my $species     = $job->species;
  my $configs     = $self->_display_config($job_data->{'configs'});
  my $two_col     = $self->new_twocol;
  my $sequence    = $object->get_input_sequence_for_job($job);
  my $job_summary = $self->get_job_summary($job, @_);
  my $result_link = $job_summary->get_nodes_by_flag('view_results_link')->[0];

  if ($result_link) {
    my $download_link = $result_link->clone_node;
    $download_link->inner_HTML('[Download results file]');
    $download_link->set_attribute('href', $hub->url('Download', {'function' => '', 'tl' => $object->create_url_param}));
    $result_link->parent_node->insert_after($download_link, $result_link);
  }

  $two_col->add_row('Job name',       $job_summary->render);
  $two_col->add_row('Search type',    $object->get_param_value_caption('search_type', $job_data->{'search_type'}));
  $two_col->add_row('Sequence',       sprintf('<div class="input-seq">&gt;%s</div>', join("\n", $sequence->{'display_id'} || '', ($sequence->{'sequence'} =~ /.{1,60}/g))));
  $two_col->add_row('Query type',     $object->get_param_value_caption('query_type', $job_data->{'query_type'}));
  $two_col->add_row('DB type',        $object->get_param_value_caption('db_type', $job_data->{'db_type'}));
  ## ParaSite: remove images and show all species on a multi-species job
  my $display_species = $job_data->{'source_species'} ? join('<br />', map($sd->species_label($_, 1), @{$job_data->{'source_species'}})) : $sd->species_label($species, 1);
  $two_col->add_row('Species',        $display_species);
  ## ParaSite
  $two_col->add_row('Source',         $object->get_param_value_caption('source', $job_data->{'source'}));
  $two_col->add_row('Configurations', $configs) if $configs;

  return $two_col;
}

1;
