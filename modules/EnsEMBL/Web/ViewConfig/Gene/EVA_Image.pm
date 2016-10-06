package EnsEMBL::Web::ViewConfig::Gene::EVA_Image;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->image_config_type('eva_variation');
  $self->set_default_options({ 'context' => 100 });
}

sub field_order { } # no default fields
sub form_fields { } # no default fields

sub init_form {
  my $self  = shift;
  my $form  = $self->SUPER::init_form(@_);

  return $form;
}

1;
