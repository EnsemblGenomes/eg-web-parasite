package Preload;

use strict;
use warnings;

preload_orm('users', ['user'], sub {
  require ORM::EnsEMBL::DB::Accounts::Object::CommentMeta;
  require ORM::EnsEMBL::DB::Accounts::Object::CommentData;
});

1;