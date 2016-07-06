=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Navigation;

use strict;
use previous qw(build_menu);

sub build_menu {
  my ($self, $node, $hub, $config, $img_url, $modal, $counts, $all_params, $active, $is_last) = @_;
  
  my $data = $node->data;
  my $availability = $data->{'availability'};

## ParaSite: create a new option named 'hide_if_unavailable' which hides the left-hand menu entry (rather than greying it out) if the view is not available  
  return if $data->{'hide_if_unavailable'} && $availability && !$self->is_available($availability);
##
  
  $self->PREV::build_menu($node, $hub, $config, $img_url, $modal, $counts, $all_params, $active, $is_last);
}

1;
