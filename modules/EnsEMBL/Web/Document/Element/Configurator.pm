package EnsEMBL::Web::Document::Element::Configurator;

# Generates the modal context navigation menu, used in dynamic pages

use strict;


sub add_image_config_notes {
  my ($self, $controller) = @_;
  my $panel   = $self->new_panel('Configurator', $controller, code => 'x', class => 'image_config_notes' );
  my $img_url = $self->img_url;

  $panel->set_content(qq(
    <h2 class="border">Key</h2>
    <div>
      <ul class="configuration_key">
        <li><img src="${img_url}render/normal.gif" /><span>Track style</span></li>
        <li><img src="${img_url}strand-f.png" /><span>Forward strand</span></li>
        <li><img src="${img_url}strand-r.png" /><span>Reverse strand</span></li>
        <li><img src="${img_url}star-on.png" /><span>Favourite track</span></li>
        <li><img src="${img_url}16/info.png" /><span>Track information</span></li>
      </ul>
    </div>
    <div>
      <ul class="configuration_key">
        <li><img src="${img_url}track-external.gif" /><span>External data</span></li>
        <li><img src="${img_url}track-user.gif" /><span>User-added track</span></li>
      </ul>
    </div>
    <p class="border space-below">Please note that the content of external tracks is not the responsibility of the WormBase ParaSite project.</p>
  ));

  $self->add_panel($panel);
}

1;

