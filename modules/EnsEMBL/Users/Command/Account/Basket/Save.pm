package EnsEMBL::Users::Command::Account::Basket::Save;

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $basket_id   = $hub->param('id');
  
  my ($basket, $record_owner) = $object->fetch_basket_with_owner($basket_id ? $basket_id : 0);

  $basket->$_($hub->param($_) || '') for qw(g object);
  $basket->save({'user' => $user});

  return $self->ajax_redirect({'action' => 'Basket',  'function' => 'View'}));
}

1;
