package ORM::EnsEMBL::DB::Accounts::Manager::CommentData;

use strict;
use warnings;

use parent qw(ORM::EnsEMBL::Rose::Manager);

# sub get_all_comments {
# 	my ($self, $gene_id) = @_;
# 	return $self->get_objects(
# 		'query' => ['gene_stable_id' => $gene_id],
# 		'with_objects'  => ['user', 'commentdata'],
# 		'select' => ['t1.*', 't2.user_id', 't2.email', 't3.data'],
# 		'sort_by' => 'created_at ASC'
# 	);
# }

sub get_all_comments {
	my ($self, $gene_id) = @_;
	return $self->get_objects_from_sql(
		args => [ $gene_id ],
		# sql  => 'SELECT * FROM comment_data WHERE data_id IN (
		# 	SELECT MAX(d.data_id) FROM comment_meta m, comment_data d
		# 	WHERE m.meta_id = d.meta_id
		# 	AND gene_stable_id = ?
		# 	GROUP BY m.meta_id
		# 	ORDER BY m.created_at ASC
		# 	)'
		sql => 'SELECT A.* FROM comment_data A
				INNER JOIN (
					SELECT MAX(data_id) AS MAXID FROM comment_data
					GROUP BY meta_id
				) AS B
					ON A.data_id=B.MAXID
				INNER JOIN comment_meta C
					ON A.meta_id=C.meta_id
				WHERE C.gene_stable_id = ?
				ORDER BY A.meta_id ASC;'
	);
}


sub get_comment_data_by_metaid {
	my ($self, $meta_id) = @_;

	return $self->get_objects(
		'query' => ['meta_id' => $meta_id],
		'sort_by' => 'data_id DESC',
		'limit' => 1
	)->[0];
}

1;