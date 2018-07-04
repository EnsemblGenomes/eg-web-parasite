package EnsEMBL::Users::Command::Account::Comment::Retrieve;

use strict;
use warnings;

use JSON;
use List::MoreUtils qw(uniq);
use Data::Dumper;

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;
  my $object = $self->object;
  my $gene_stable_id = $hub->param('geid');

  my @comment_result;

  #warn "Comment id $gene_stable_id";

  #Solution 1: Calling get all comments from Data
  # my @comments = @{$object->get_comment($gene_stable_id)}; #It's return only reference

  # warn Dumper(@comments);

  # for my $comment (@comments) {
  # 	warn sprintf ("Comment id %s data %s of user", $comment->data_id, $comment->data);

  #   my $created_at = $self->convert_time_to_uk($comment->commentmeta->created_at);
  #   my $display_time = $created_at->strftime('%Y-%m-%d %H:%M:%S UK');

  #     push @comment_result, {
  #       'timestamp' => $display_time,
  #     	'user' => $comment->commentmeta->user->email,
  #       'uuid' => $comment->commentmeta->comment_uuid,
  #       'comment_data' => $comment->data,
  #       'id' => $comment->data_id
  #     };
  # }

  my @comments = @{$object->get_comment_meta($gene_stable_id)}; #It's return only reference

  for my $comment (@comments) {
    #warn sprintf ("Comment id %s data of user %s", $comment->meta_id, $comment->user_id);

    my $created_at = $self->convert_time_to_uk($comment->created_at);
    my $display_time = $created_at->strftime('%Y-%m-%d %H:%M:%S UK');
    my $comment_data = $object->get_comment_data($comment->meta_id);
    my $isEditable = $self->hasEditPermission($comment->user_id);
    $isEditable = $isEditable ? 'true' : 'false';
    
    my $diff = $comment_data->created_at->epoch - $comment->created_at->epoch;
    my $wasEdited = ($diff > 60) ? 'true' : 'false';

      push @comment_result, {
        'timestamp' => $display_time,
        'user' => $comment->user->name,
        'uuid' => $comment->comment_uuid,
        'comment_data' => $comment_data->data,
        'isEditable' => $isEditable,
        'wasEdited'  => $wasEdited
      };
  }
  
  $self->r->content_type('application/json');
  print to_json(\@comment_result);
  
}

sub convert_time_to_uk {
  my ($self, $dt) = @_;

  #Floating timezone by default
  $dt->set_time_zone('UTC');
  $dt->set_time_zone('Europe/London');
  return $dt;
}

1;
