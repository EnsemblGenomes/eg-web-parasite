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

package EnsEMBL::Web::Document::Element::ToolButtons;

use strict;

sub label_classes {
  return {
    'Configure tracks'    => 'config',
    'Configure this page' => 'config',
    'Add custom tracks'   => 'data',
    'Export data'         => 'export',
    'Share this page'     => 'share',
  };
}

sub init {
  my $self       = shift;
  my $controller = shift;
  my $hub        = $self->hub;
  my $object     = $controller->object;
  my @components = @{$hub->components};
  my $session    = $hub->session;
  my $user       = $hub->user;
  my $view_config;
     $view_config = $hub->get_viewconfig(@{shift @components}) while !$view_config && scalar @components;

  if ($view_config) {
    my $component = $view_config->component;

    $self->add_entry({
      caption => $view_config->type eq 'Location' ? 'Configure tracks' : 'Configure this page',
      class   => $view_config->type eq 'Location' ? 'modal_link config-tracks' : 'modal_link',
      rel     => "modal_config_$component",
      url     => $hub->url('Config', {
        type      => $view_config->type,
        action    => $component,
        function  => undef,
      })
    });

   if($hub->species_defs->RNASEQ && $view_config->type eq 'Location') {
     $self->add_entry({
       caption => 'Add RNA-Seq tracks',
       class   => 'modal_link config-tracks config',
       rel     => "modal_config_$component",
       url     => $hub->url('Config', {
          type     => $view_config->type,
          action   => $component,
          function => 'parasite_rnaseq',
       })
     });
   }

    if($view_config->type eq 'Location') {
      $self->add_entry({
        caption => 'Add custom tracks',
        class   => 'modal_link',
        rel     => 'modal_user_data',
        url     => $hub->url({
          time    => time,
          type    => 'UserData',
          action  => 'ManageData',
          __clear => 1
        })
      });
    }
  }

  if ($object && $object->can_export) {
    $self->add_entry({
      caption => 'Export data',
      class   => 'modal_link',
      url     => $self->export_url($hub)
    });
  }

  $self->add_entry({
    caption => 'Share this page',
    url     => $hub->url('Share', {
      __clear => 1,
      create  => 1,
      time    => time
    })
  });

  $self->add_entry({
    caption => 'Add to saved gene list',
    class   => 'modal_link',
    url     => $hub->url({
      type      => 'Account',
      __clear   => 1,
      action    => 'Basket/Add',
      gene_id   => $hub->param('g')
    })
  });

}

1;

