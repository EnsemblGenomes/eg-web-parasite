package EnsEMBL::Users::Command::Account::Basket::Save;

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $basket_id = $hub->param('id');

  my $basket = $object->fetch_basket($basket_id);

  $basket->$_($hub->param($_) || '') for qw(gene_id object);
  $basket->save({'user' => $user});
  
  return;
}

1;
