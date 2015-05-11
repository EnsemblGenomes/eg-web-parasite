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

package EnsEMBL::Web::Component::Tools::TicketsList;

use strict;
use warnings;

sub job_summary_section {
  my ($self, $ticket, $job, $result_count) = @_;

  my $hub               = $self->hub;
  my $object            = $self->object;
  my $url_param         = $object->create_url_param({'ticket_name' => $ticket->ticket_name, 'job_id' => $job->job_id});
  my $action            = $ticket->ticket_type_name;
  my $species_defs      = $hub->species_defs;
  my $dispatcher_status = $job->dispatcher_status;
  my $job_species       = $job->species;
  my $valid_job_species = $species_defs->tools_valid_species($job_species);
  my $job_assembly      = $job->assembly;
  my $current_assembly  = $valid_job_species ? $species_defs->get_config($job_species, 'ASSEMBLY_VERSION') : '0';
## ParaSite mod to allow Multi as a species job submission name
  my $assembly_mismatch = $job_assembly ne $current_assembly && $job_assembly ne 'Multi';
## ParaSite
  my $switch_assembly   = $species_defs->get_config($job_species, 'SWITCH_ASSEMBLY') || '';
  my $assembly_site     = $assembly_mismatch && $switch_assembly eq $job_assembly ? 'http://'.$species_defs->get_config($job_species, 'SWITCH_ARCHIVE_URL') : '';
  my $job_description   = $object->get_job_description($job);

  my $job_species_display = $valid_job_species ? $species_defs->species_label($job_species, 1) : $job_species =~ s/_/ /rg;

  my $result_url = $dispatcher_status eq 'done' ? {
    '__clear'     => !!$assembly_site, # remove extra params for the external site
    'species'     => $job_species,
    'type'        => 'Tools',
    'action'      => $ticket->ticket_type_name,
    'function'    => 'Results',
    'tl'          => $url_param
  } : undef;

  if ($result_url && $assembly_mismatch) {
    if ($assembly_site && $ticket->owner_type eq 'user') { # if job is from another assembly and we do have a site for that assembly
      $result_url = { # result can only be seen by logged in user
        'then'      => $hub->url($result_url),
        'type'      => 'Account',
        'action'    => 'Login',
      };
    } else { # if job is from another assembly and we do NOT have a site for that assembly
      $result_url = undef;
    }
  }

  return $self->dom->create_element('p', {
    'children'    => [{
      'node_name'   => 'span',
      'class'       => ['right-margin'],
      'flags'       => ['job_desc_span'],
      'inner_HTML'  => "$job_species_display: $job_description"
    },
    $self->job_status_tag($job, $dispatcher_status, $result_count, $assembly_mismatch && $current_assembly, !!$assembly_site),
    $result_url ? {
      'node_name'   => 'a',
      'inner_HTML'  => $assembly_site ? "[View results on $job_assembly site]" : '[View results]',
      'flags'       => ['job_results_link'],
      'class'       => [qw(small left-margin)],
      'href'        => sprintf('%s%s', $assembly_site, $hub->url($result_url))
    } : (), {
      'node_name'   => 'span',
      'class'       => ['job-sprites'],
      'children'    => [{
        'node_name'   => 'a',
        'class'       => [qw(_ticket_view _change_location job-sprite)],
        'href'        => $hub->url({'action' => $action, 'function' => 'View', 'tl' => $url_param}),
        'children'    => [{
          'node_name'   => 'span',
          'class'       => [qw(_ht sprite view_icon)],
          'title'       => 'View details'
        }]
      }, {
        'node_name'     => 'a',
        'class'         => [qw(_ticket_edit _change_location job-sprite)],
        'href'          => $hub->url({'action' => $action, 'function' => 'Edit', 'tl' => $url_param}),
        'children'      => [{
          'node_name'     => 'span',
          'class'         => [qw(_ht sprite edit_icon)],
          'title'         => 'Edit &amp; resubmit job (create a new ticket)'
        }]
      }, {
        'node_name'     => 'a',
        'class'         => [qw(_json_link job-sprite)],
        'href'          => $hub->url('Json', {'action' => $action, 'function' => 'delete', 'tl' => $url_param}),
        'children'      => [{
          'node_name'     => 'span',
          'class'         => [qw(_ht sprite delete_icon)],
          'title'         => 'Delete job'
        }, {
          'node_name'     => 'span',
          'class'         => [qw(hidden _confirm)],
          'inner_HTML'    => qq(This will delete the following job permanently:\n$job_description)
        }]
      }]}
    ]
  });
}

1;
