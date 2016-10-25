package EnsEMBL::Web::Configuration::Account;

use previous qw(modify_tree);

sub modify_tree {

  my $self = shift;
  $self->PREV::modify_tree(@_);

  my $preference_menu = $self->get_node('Preferences');

   $preference_menu->append($self->create_node('Basket/View', 'View basket', [
     'add_basket'      =>  'EnsEMBL::Users::Component::Account::Basket::View'
   ], { 'availability'   =>  1 }));

   $preference_menu->append($self->create_node('Basket/Add', 'Add gene to basket', [
     'add_basket'      =>  'EnsEMBL::Users::Component::Account::Basket::AddEdit'
   ], { 'availability'   =>  1 }));

}

1;

