=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

# $Id: Tabs.pm,v 1.4 2012-12-17 14:18:30 nl2 Exp $

package EnsEMBL::Web::Document::Element::Tabs;

sub init {
  my $self          = shift;
  my $controller    = shift;
  my $builder       = $controller->builder;
  my $object        = $controller->object;
  my $configuration = $controller->configuration;
  my $hub           = $controller->hub;
  my $type          = $hub->type;
  my $action        = $hub->action;
  my $species_defs  = $hub->species_defs;  
  my @data;
  
  # add species tab if species selected
  if ($species_defs->valid_species($hub->species) && $action ne 'SpeciesLanding') {
    push (@data, {
      class    => 'species',
      type     => 'Info',
      action   => 'Index',
      caption  => $species_defs->SPECIES_COMMON_NAME,
      dropdown => $species_defs->DISABLE_SPECIES_DROPDOWN ? 0 : 1
    });
  }

  $self->init_history($hub, $builder) if $hub->user;
  $self->init_species_list($hub);
  
  foreach (@{$builder->ordered_objects}) {
    my $o = $builder->object($_);
    push @data, { type => $_, action => $o->default_action, caption => $o->short_caption('global'), dropdown => !!($self->{'history'}{lc $_} || $self->{'bookmarks'}{lc $_} || $_ eq 'Location') } if $o;
  }
 
  push @data, { type => $object->type,        action => $object->default_action,        caption => $object->short_caption('global')       } if $object && !@data;
  push @data, { type => $configuration->type, action => $configuration->default_action, caption => $configuration->{'_data'}->{'default'} } if $type eq 'Location' && !@data;
  
  foreach my $row (@data) {
    next if $row->{'type'} eq 'Location' && $type eq 'LRG';
    
    my $class = $row->{'class'} || lc $row->{'type'};
    
    $self->add_entry({
      type     => $row->{'type'}, 
      caption  => $row->{'caption'},
      url      => $row->{'url'} || $hub->url({ type => $row->{'type'}, action => $row->{'action'} }),
      class    => $class . ($row->{'type'} eq $type ? ' active' : ''),
      dropdown => $row->{'dropdown'} ? $class : '',
      disabled => $row->{'disabled'}
    });
  }
}

1;

