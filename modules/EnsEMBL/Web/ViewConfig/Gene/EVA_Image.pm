package EnsEMBL::Web::ViewConfig::Gene::EVA_Image;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('eva_variation');
  $self->title = 'Variation Image';
}

1;