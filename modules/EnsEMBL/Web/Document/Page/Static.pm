=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Page::Static;

use strict;
use base qw(EnsEMBL::Web::Document::Page);
use previous qw(initialize_HTML);

sub initialize_HTML {
  my $self = shift;
  
  $self->PREV::initialize_HTML(@_);
  
  ## ParaSite: we want to remove the search and tool links from the homepage only
  my $here = $ENV{'REQUEST_URI'};
  my $is_home = $here =~ /\/index.html/ ? 1 : 0;
  if($is_home) {
    $self->remove_body_element('search_box');
    $self->remove_body_element('tools');
  }
  ## ParaSite
}

1;
