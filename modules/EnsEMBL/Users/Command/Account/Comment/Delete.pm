package EnsEMBL::Users::Command::Account::Comment::Delete;

use strict;
use warnings;

use JSON;
use List::MoreUtils qw(uniq);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;
  my $object = $self->object;
  my $comment_uuid = $hub->param('uuid');
  #my $undelete = $hub->param('recover');

  my $comment_meta = $object->fetch_comment_meta_by_uuid($comment_uuid);
  #warn "Is it in transaction ". $comment_meta->db->in_transaction;
  my $isEditable = $self->hasEditPermission($comment_meta->user_id);
  
  if (!$isEditable) {
    print to_json({'deleted' => 0});
    return;
  }

  $comment_meta->remove;
  $comment_meta->save;

  print to_json({'deleted' => 1});

}

1;