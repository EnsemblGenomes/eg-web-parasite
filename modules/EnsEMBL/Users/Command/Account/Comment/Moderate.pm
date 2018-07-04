package EnsEMBL::Users::Command::Account::Comment::Moderate;

use strict;
use warnings;

use JSON;
use List::MoreUtils qw(uniq);
use Data::Dumper;
use POSIX 'strftime';
use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;
  my $object = $self->object;
  my @comment_result;
  my @comments;
  my $limit = $hub->param('limit');
  my $from = $hub->param('from');
  my $MAX_LIMIT = 5000;

  if (defined $limit) {
    @comments = @{$object->get_all_comments($limit)};
  } elsif (defined $from) {
    my $fromTime = strftime("%Y-%m-%d %H:%M:%S", gmtime($from));
    #warn "Get epoch $from which is equivalent to $fromTime";
    @comments = @{$object->get_all_comments(undef, $fromTime)};
  } else {
    @comments = @{$object->get_all_comments($MAX_LIMIT)};
  }

  for my $comment (@comments) {
    #warn sprintf ("Comment id %s data of user %s", $comment->meta_id, $comment->user_id);

    my $created_at = $self->convert_time_to_uk($comment->created_at);
    my $created_at_display = $created_at->strftime('%Y-%m-%d %H:%M:%S UK');
    my $changed_at = $self->convert_time_to_uk($comment->modified_at);
    my $changed_at_display = $changed_at->strftime('%Y-%m-%d %H:%M:%S UK');
    my $comment_data = $comment->commentdata->[-1];

    my $isEditable = $self->hasEditPermission($comment->user_id);
    $isEditable = $isEditable ? 'true' : 'false';
    my $diff = $comment_data->created_at->epoch - $comment->created_at->epoch;
    my $wasEdited = ($diff > 60) ? 'true' : 'false';

      push @comment_result, {
        'posted_on' => $created_at_display,
        'changed_on' => $changed_at_display,
        'user' => $comment->user->name,
        'uuid' => $comment->comment_uuid,
        'comment_data' => $comment_data->data,
        'species'   => $comment->species,
        'geneid'    => $comment->gene_stable_id,
        'isEditable' => $isEditable,
        'wasEdited'  => $wasEdited,
        'wasDeleted' => $comment->isRemoved ? 'true' : 'false'
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
