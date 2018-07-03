package ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta;

use strict;
use warnings;

use parent qw(ORM::EnsEMBL::Rose::Manager);


sub get_comment_meta_with_user {
	my ($self, $gene_id) = @_;
	return $self->get_objects(
		'query' => ['gene_stable_id' => $gene_id, 'isRemoved' => 0],
		'with_objects'  => ['user'],
		'sort_by' => 'created_at ASC'
	);

}

sub get_by_uuid {
  my ($class, $uuid) = @_;

  return $uuid ? $class->get_objects('query' => [ 'comment_uuid', $uuid ])->[0] : undef;
}

sub get_comment_count_by_geneid {
	my ($self, $gene_id) = @_;
	return $self->count(
		{'query' => ['gene_stable_id' => $gene_id, 'isRemoved' => 0]}
		)
}

sub get_all_latest_comment {
	my ($self, $limit, $from) = @_;

	if (defined $limit) {
		return $self->get_objects(
			'with_objects'  => ['user', 'commentdata'],
			'sort_by' => 'modified_at DESC',
			'limit' => $limit
		)
	}

	if (defined $from) {
		return $self->get_objects(
			'with_objects'  => ['user', 'commentdata'],
			'sort_by' => 'modified_at DESC',
			'query' => [
				modified_at => { ge => $from}
			]
		)
	}
}

1;