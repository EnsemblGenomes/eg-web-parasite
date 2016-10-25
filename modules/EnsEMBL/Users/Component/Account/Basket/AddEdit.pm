package EnsEMBL::Users::Component::Account::Basket::AddEdit;

use strict;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self          = shift;
  my $object        = $self->object;
  my $hub           = $self->hub;
  my $user          = $hub->user;
  my $is_add_new    = $hub->function eq 'Add';

  my ($basket, $record_owner) = $object->fetch_basket_with_owner( $is_add_new ? 0 : ($hub->param('id'), $hub->param('group')) );

  my $form = $self->new_form({'action' => {qw(action Basket function Save)}, 'csrf_safe' => 1});

  $form->add_hidden({'name' => 'id',              'value' => $basket->record_id });
  $form->add_hidden({'name' => 'object',          'value' => $basket->name || $hub->referer->{'ENSEMBL_TYPE'} }) if $is_add_new;
  $form->add_hidden({'name' => $self->_JS_CANCEL, 'value' => $hub->PREFERENCES_PAGE });

  $form->add_field({'type'  => 'string', 'name'  => 'g', 'label' => 'Gene ID', 'value' => $is_add_new ? $hub->param('g') || '' : $basket->g,  'required' => 1 });

  my @buttons = ({'type' => 'submit', 'name' => 'button', 'value' => $is_add_new ? 'Add' : 'Save'});

  push @buttons, {'type' => 'reset', 'value' => 'Cancel', 'class' => $self->_JS_CANCEL};

  $form->add_field({'inline' => 1, 'elements' => \@buttons});

  return $self->js_section({'subsections' => [ $form->render ]});

}

1;
