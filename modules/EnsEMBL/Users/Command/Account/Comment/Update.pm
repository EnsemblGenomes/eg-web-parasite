package EnsEMBL::Users::Command::Account::Comment::Update;

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
  #my $comment = join ',', uniq split ',', $hub->param('cmt') || ''; # 'uniq' preserves order too
  my $comment = $hub->param('cmt') || '';

  my $comment_meta = $object->fetch_comment_meta_by_uuid($comment_uuid);

  #warn "Is it in transaction ". $comment_meta->db->in_transaction;
  my $isEditable = $self->hasEditPermission($comment_meta->user_id);

  if (!$isEditable) {
    print to_json({'updated' => 0});
    return;
  }

  
  my $new_comment_data = $object->new_comment_data({ 'data' => $comment });
  $comment_meta->save('user' => $user);
  $comment_meta->commentdata($new_comment_data);
  $new_comment_data->save('user' => $user);
  #$comment_meta->save('user' => $user); #To update modified_at field??

  print to_json({'updated' => 1});
}

1;