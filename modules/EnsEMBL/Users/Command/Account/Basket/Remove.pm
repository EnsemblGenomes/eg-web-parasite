package EnsEMBL::Users::Command::Account::Basket::Remove;

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DELETE_BOOKMARK MESSAGE_BOOKMARK_NOT_FOUND);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $basket_id   = $hub->param('id');

  if (my ($basket, $owner) = $object->fetch_basket_with_owner( $basket_id ? ($basket_id, $hub->param('group')) : 0 )) {

    $basket->delete;

    return $self->ajax_redirect($hub->url({'action' => 'Basket', 'function' => 'View'}));

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND, {'error' => 1});
  }
}

1;

