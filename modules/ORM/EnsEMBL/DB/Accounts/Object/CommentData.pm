package ORM::EnsEMBL::DB::Accounts::Object::CommentData;

use strict;
use warnings;

use parent qw(ORM::EnsEMBL::DB::Accounts::Object);

__PACKAGE__->meta->setup(
  table           => 'comment_data',

  columns         => [
    data_id        	=> {'type' => 'serial', 'primary_key' => 1, 'not_null' => 1},
    meta_id     => {'type' => 'int', 'length' => '11'},
    data         	=> {'type' => 'text'},
  ],

  trackable       => 1,

  relationships   => [
    commentmeta            => {
      'type'          => 'many to one',
      'class'         => 'ORM::EnsEMBL::DB::Accounts::Object::CommentMeta',
      'column_map'    => {'meta_id' => 'meta_id'},
    }
  ]
);

1;