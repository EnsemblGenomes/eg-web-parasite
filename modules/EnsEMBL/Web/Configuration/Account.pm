package EnsEMBL::Web::Configuration::Account;
use base qw(EnsEMBL::Web::Configuration);
use previous qw(populate_tree);


sub populate_tree {
	my $self = shift;
    my $hub       = $self->hub;
  	my $user      = $hub->user;

  	$self->PREV::populate_tree(@_);

  	return unless ($SiteDefs::PARASITE_COMMENT_ENABLED);

  	if ($hub->users_available) {
		if ($user) {
			$self->create_node( 'Comment/Add',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Comment::Save' });
			$self->create_node( 'Comment/Delete',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Comment::Delete' });
			$self->create_node( 'Comment/Update',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Comment::Update' });
			$self->create_node( 'Comment/Admin',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Comment::Moderate' });
		}

		$self->create_node( 'Comment/Get',  '', [], { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::Comment::Retrieve' });
	}
}

1;
