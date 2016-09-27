package EnsEMBL::Web::ViewConfig::Gene::EVA_Image;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->image_config_type('eva_variation');
  $self->set_default_options({ 'context' => 100 });
}

1;
