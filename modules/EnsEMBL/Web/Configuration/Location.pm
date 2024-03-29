=head1 LICENSE

Copyright [2014-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::Location;

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $species = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object = $self->object;

  my $view = $self->get_node('View');
  $view->set_data('genoverse', 1) if $view;

  my $compara_alignments_node = $self->get_node('Compara_Alignments/Image');
  $compara_alignments_node->set_data('genoverse', 1) if $compara_alignments_node;

  $self->delete_node('Variation');
  $self->delete_node('Marker');
  $self->delete_node('Compara');

  ## ParaSite: add an additional component for WormBase JBrowse
  my $view = $self->get_node('View');
  $view->set('components', 
    [qw(
      summary  EnsEMBL::Web::Component::Location::Summary
      wormbase EnsEMBL::Web::Component::WormBaseLink
      top      EnsEMBL::Web::Component::Location::ViewTop
      botnav   EnsEMBL::Web::Component::Location::ViewBottomNav
      bottom   EnsEMBL::Web::Component::Location::ViewBottom
    )]
  );

  $self->create_node('EVA_Variant', 'Variant Information',
    [qw(eva_variant EnsEMBL::Web::Component::Location::EVA_Variant)],
    { 'no_menu_entry' => 1 }
  );

  ## ParaSite

}

1;
