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

package EnsEMBL::Users::Command::Account;

use strict;
use warnings;


sub hasEditPermission {
  my ($self, $comment_owner_id) = @_;

  return 0 unless ($self->hub->users_available && $self->hub->user);
  
  my $current_user_id = $self->hub->user->rose_object->user_id;

  if (defined $self->hub->user->group($self->hub->species_defs->COMMENT_ADMIN_GROUP)) {
    return 1;
  }
  return $current_user_id eq $comment_owner_id ? 1 : 0;
}

1;
