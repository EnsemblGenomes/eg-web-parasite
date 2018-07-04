=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Object::Account;

use strict;
use ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta;
use ORM::EnsEMBL::DB::Accounts::Manager::CommentData;

use parent qw(EnsEMBL::Web::Object);

sub new_comment_meta { 
	return ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta->create_empty_object($_[1]);
}

sub new_comment_data { 
	return ORM::EnsEMBL::DB::Accounts::Manager::CommentData->create_empty_object($_[1]);      
}

sub get_comment {
  return ORM::EnsEMBL::DB::Accounts::Manager::CommentData->get_all_comments($_[1]);
}

sub get_comment_meta {
  return ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta->get_comment_meta_with_user($_[1]);
}

sub get_comment_data {
  return ORM::EnsEMBL::DB::Accounts::Manager::CommentData->get_comment_data_by_metaid($_[1]);
}

#Return N latest comments on all Genes
sub get_all_comments {
  return ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta->get_all_latest_comment($_[1], $_[2]);
}

sub fetch_comment_meta_by_uuid {
  return ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta->get_by_uuid($_[1]);
}