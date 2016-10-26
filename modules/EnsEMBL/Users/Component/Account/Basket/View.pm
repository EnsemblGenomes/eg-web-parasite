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

sub basket_table {
  my ($self, $params) = @_;

  my $user        = $self->hub->user;
  my $table       = $self->new_table([{
    'key'           => 'g',
    'title'         => 'Gene ID',
    'width'         => '90%',
    'sort'          => 'html'
  }, {
    'key'           => 'buttons',
    'title'         => '',
    'width'         => '10%',
    'sort'          => 'none'
  }], [], {'class' => 'tint', 'data_table' => 'no_col_toggle', 'exportable' => 0});

  for (@{$params->{'basket'}}) {
    my $basket_id   = $_->get_primary_key_value;
    my $basket_row  = { 'g' => $self->html_encode($_->data->{'g'}) };

    $basket_row->{'buttons'} = sprintf '<div class="sprites-nowrap">%s</div>', join('',
      $self->js_link({
        'href'    => {'action' => 'basket', 'function' => 'Edit', 'id' => $basket_id},
        'helptip' => 'Edit',
        'sprite'  => 'edit_icon'
      }), $self->js_link({
        'href'    => {'action' => 'basket', 'function' => 'Remove', 'id' => $basket_id, 'csrf_safe' => 1},
        'helptip' => 'Remove',
        'sprite'  => 'delete_icon',
        'confirm' => 'You are about to remove the gene from the basket. This action can not be undone.'
      })
    );

    $table->add_row($basket_row);
  }

  return $table->render;
}

1;
