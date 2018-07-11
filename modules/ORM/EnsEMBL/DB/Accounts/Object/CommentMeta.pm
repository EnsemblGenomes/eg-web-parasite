package ORM::EnsEMBL::DB::Accounts::Object::CommentMeta;

use strict;
use warnings;

use parent qw(ORM::EnsEMBL::DB::Accounts::Object);

__PACKAGE__->meta->setup(
  table           => 'comment_meta',

  columns   => [
    meta_id         => {'type' => 'serial', 'primary_key' => 1, 'not_null' => 1},
    comment_uuid    => {'type' => 'varchar', 'length' => '50', 'not_null' => 1},
    user_id         => {'type' => 'int', 'length'  => '11'},
    species         => {'type' => 'varchar', 'length' => '100', 'not_null' => 1},
    gene_stable_id 	=> {'type' => 'varchar', 'length' => '100', 'not_null' => 1},
    isRemoved			  => {'type' => 'tinyint', 'default' => 0},
  ],

  trackable       => 1,

  relationships   => [
    user            => {
      'type'          => 'many to one',
      'class'         => 'ORM::EnsEMBL::DB::Accounts::Object::User',
      'column_map'    => {'user_id' => 'user_id'},
    },
    commentdata         => {
      'type'          => 'one to many',
      'class'         => 'ORM::EnsEMBL::DB::Accounts::Object::CommentData',
      'column_map'    => {'meta_id' => 'meta_id'},
    },
  ]
);

sub remove {
  my $self = shift;
  $self->isRemoved(1);
}

1;