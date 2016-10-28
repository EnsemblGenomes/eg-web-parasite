package EnsEMBL::Web::Configuration::Account;

use previous qw(modify_tree);

sub modify_tree {

  my $self = shift;
  $self->PREV::modify_tree(@_);

  my $preference_menu = $self->get_node('Preferences');

  if($preference_menu) {
    $preference_menu->append($self->create_node('Basket/View', 'View BioMart gene list', [
      'add_basket'      =>  'EnsEMBL::Users::Component::Account::Basket::View'
    ], { 'availability'   =>  1 }));
  
    $preference_menu->append($self->create_node('Basket/Add', 'Add gene to BioMart gene list', [
      'add_basket'      =>  'EnsEMBL::Users::Component::Account::Basket::AddEdit'
    ], { 'availability'   =>  1 }));
  
    $self->create_node("Basket/$_", '', [], { 'no_menu_entry' => 1, 'command' => "EnsEMBL::Users::Command::Account::Basket::$_"   }) for qw(Save Remove);
  
  }

  foreach(qw(Bookmark/View Bookmark/Edit Bookmark/Add Share/Bookmark)) {
    $self->delete_node($_);
  }

}

1;

