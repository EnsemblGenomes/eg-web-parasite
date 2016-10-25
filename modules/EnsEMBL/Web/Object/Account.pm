package EnsEMBL::Web::Object::Account;

use strict;

sub fetch_basket_with_owner {
  ## Fetches basket for the logged-in user with given basket id
  ## @param Bookmark record id (if 0, a new record is created)
  ## @param Group id (optional) if the basket is owned by a group
  ## @return List: Bookmark (RecordSet) object and owner of the basket (ie. either a group object, or the user object itself)
  my ($self, $basket_id, $group_id) = @_;
  my $owner = $self->hub->user;

  if ($basket_id) {
    if ($group_id) {
      my $membership = $self->fetch_accessible_membership_for_user($owner->rose_object, $group_id, {'query' => ['group.status' => 'active']});
      $owner = $membership ? $self->web_group($membership->group) : undef;
    }

    if ($owner && (my $basket = $owner->record({'record_id' => $basket_id}))) {
      return ($basket, $owner);
    }
  } elsif (defined $basket_id) {
    return ($owner->add_record('basket'), $owner);
  }

  return ();
}

1;

