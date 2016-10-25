package EnsEMBL::Users::Component::Account::Basket::View;

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $user            = $hub->user;
  my $basket          = $user->basket;

  return join '',
    $self->js_section({
      'heading'           => 'Basket',
      'heading_links'     => [{
        'href'              => {qw(action Basket function Add)},
        'title'             => 'Add gene to basket',
        'sprite'            => 'basket_icon'
      }],
      'subsections'       => [ @$basket ? $self->basket_table({'basket' => $basket}) : $self->no_bookmark_message ]
    });
}

1;
