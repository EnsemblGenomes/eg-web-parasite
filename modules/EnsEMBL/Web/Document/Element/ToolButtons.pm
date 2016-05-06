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
  my $has_data   = $self->_has_data;
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

    if($view_config->type eq 'Location') {
      $self->add_entry({
        caption => 'Add custom tracks',
        class   => 'modal_link',
        rel     => 'modal_user_data',
        url     => $hub->url({
          time    => time,
          type    => 'UserData',
          action  => $has_data ? 'ManageData' : 'SelectFile',
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

}

1;

