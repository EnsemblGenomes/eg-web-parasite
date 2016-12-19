package EnsEMBL::Web::ViewConfig::Transcript::ChEMBLHits;

use strict;

use EnsEMBL::Web::Constants;

use parent qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;

  $self->set_default_options({
    e_value  => 0
  });
}

sub init_form {
  my $self = shift;
  
  $self->add_form_element({
    type   => 'dropdown',
    select => 'select',
    name   => 'e_value',
    label  => 'E-value cut-off threshold',
    values => [
      { value => '0',    'name' => 'Show All Hits'},
      { value => '0.1',  'name' => '0.1'},
    ]
  });
}

1;

