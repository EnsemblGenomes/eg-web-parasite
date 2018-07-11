package EnsEMBL::Users::Command::Account::Comment::Save;

use strict;
use warnings;

use JSON;
use Data::UUID;

use parent qw(EnsEMBL::Users::Command::Account);


sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;
  my $object = $self->object;
  my $comment = $hub->param('cmt');
  my $species = $hub->param('spec');
  my $geid = $hub->param('geid');
  
  return 0 unless ($hub->users_available && $user);
  if (!defined $comment || !defined $species || !defined $geid) {
    print to_json({'error' => 'Not providing required parameters'});
    return 1;
  }

  my $user_id = $user->rose_object->user_id;

  defined ($species) ? warn "Species is $species" : warn "It's nothing for species";
  my $uuid = Data::UUID->new()->create_str();

  my $new_comment_meta = $object->new_comment_meta({ 'gene_stable_id' => $geid, 'species' => $species, 'comment_uuid' => $uuid, 'user_id' => $user_id});
  my $new_comment_data = $object->new_comment_data({ 'data' => $comment });
  
  $new_comment_meta->commentdata($new_comment_data);

  $new_comment_meta->save('user' => $user);
  $new_comment_data->save('user' => $user);
  
  #my $db =   $new_comment_meta->db;
  #warn "Is it in transaction ". $db->in_transaction;
  #warn "Id is : ". $new_comment_meta->meta_id;
  #warn "Error with db " . $db->error if $db->error;

  print to_json({'saved' => 1});
}

1;