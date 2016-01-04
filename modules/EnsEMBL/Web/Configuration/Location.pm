=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

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
use Data::Dumper;

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $species = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object = $self->object;

  $self->delete_node('Overview');
  $self->delete_node('Variation');
  $self->delete_node('Marker');
  $self->delete_node('Compara');
  $self->delete_node('Chromosome');

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
  my $overview = $self->get_node('Overview');
  $overview->set('components', 
    [qw(
      summary  EnsEMBL::Web::Component::Location::Summary
      wormbase EnsEMBL::Web::Component::WormBaseLink
      nav      EnsEMBL::Web::Component::Location::ViewBottomNav/region
      top      EnsEMBL::Web::Component::Location::Region
    )]
  );
  ## ParaSite

}

1;
