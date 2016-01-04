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

package EnsEMBL::Web::Component::Tools::Blast::InputForm;

use strict;
use warnings;
use URI;
use previous qw(get_cacheable_form_node);
use List::Util qw(min);

sub get_cacheable_form_node {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $form            = $self->PREV::get_cacheable_form_node(@_);
  my $default_species = $species_defs->valid_species($hub->species) ? $hub->species : '';

  my @species         = $hub->param('species') || $default_species;
  my $list = ''; my $checkboxes = '';
  if($hub->param('species') || $default_species) {
    $list            = join '<br />', map { $species_defs->species_display_label($_) } @species;
    $checkboxes      = join '<br />', map { sprintf('<input type="checkbox" name="species" value="%s" checked>%s', $_, $_) } @species;
  }

  # set uri for the modal link
  my $url_species = $species_defs->valid_species($default_species) ? $default_species : 'Multi';
  my $modal_uri = URI->new("/${url_species}/Component/Blast/Web/TaxonSelector/ajax?");
  $modal_uri->query_form(s => [map {lc($_)} @species]); 

  # Render the taxonomy groups - get this from the ini files
  my $groups;
  my $subgroups;
  $groups .= sprintf(qq(<input type="radio" name="species_group" id="all" value="all" %s onclick="Ensembl.Panel.BlastForm.prototype.definedSpecies('all')" /><label for="all">All species</label>&nbsp;), ($url_species eq 'Multi' ? 'checked="true"' : ''));
  foreach my $group (@{$species_defs->TAXON_ORDER}) {
    $groups .= sprintf(qq(<input type="radio" name="species_group" id="%s" value="%s" onclick="Ensembl.Panel.BlastForm.prototype.definedSpecies('%s')" /><label for="%s">%s</label>&nbsp;), $group, $group, $group, $group, $species_defs->TAXON_COMMON_NAME->{$group} || $group);
    $subgroups .= qq(<div class="subgroups" id="subgroups-$group" style="display:none">);
    $subgroups .= sprintf(qq(<input type="radio" name="species_%s" id="all-%s" value="all" checked="true" onclick="Ensembl.Panel.BlastForm.prototype.definedSpecies('%s')" /><label for="all-%s">All</label>&nbsp;), $group, $group, $group, $group);
    foreach my $subgroup (@{$species_defs->TAXON_SUB_ORDER->{$group}}) {
      $subgroups .= sprintf(qq(<input type="radio" name="species_$group" id="%s" value="%s" onclick="Ensembl.Panel.BlastForm.prototype.definedSpecies('%s')" /><label for="%s">%s</label>&nbsp;), $subgroup, $subgroup, $group, $subgroup, $species_defs->TAXON_COMMON_NAME->{$subgroup} || $subgroup);
    }
    $subgroups .= '</div>';
  }
  $groups .= sprintf(qq(<input type="radio" name="species_group" id="custom" value="custom" %s onclick="Ensembl.Panel.BlastForm.prototype.customSpecies()" /><label for="custom">Custom species list</label>&nbsp;), ($url_species ne 'Multi' ? 'checked="true"' : ''));
  my $selector_style = $url_species ne 'Multi' ? '' : 'display:none';

  # Render the hidden species groupings
  my %lookup;
  foreach my $group (keys $species_defs->TAXON_MULTI) {
    map($lookup{$_} = $group, @{$species_defs->TAXON_MULTI->{$group}});
  }
  foreach my $sp ($species_defs->valid_species) {
    $groups .= sprintf('<input type="hidden" name="species_taxon" value="%s" class="%s %s" />', $sp, $species_defs->get_config($sp, 'SPECIES_GROUP'), $lookup{$species_defs->get_config($sp, 'SPECIES_SUBGROUP')} || $species_defs->get_config($sp, 'SPECIES_SUBGROUP')),
  }

  # Populathe the species checkboxes with everything if no species selected
  $checkboxes = join '<br />', map { sprintf('<input type="checkbox" name="species" value="%s" checked>%s', $_, $_) } $species_defs->valid_species if $url_species eq 'Multi';

  my $html = qq{
    <div style="display:none">
      <input type="radio" name="species_select" id="concat" value="concat" checked="true" /><label for="concat">Combine results for all species</label>&nbsp;
      <input type="radio" name="species_select" id="individual" value="individual" onclick="Ensembl.Panel.BlastForm.prototype.checkSpeciesChecked()" /><label for="individual">Separate results by species (maximum 25 species)</label>&nbsp;
    </div>
    <div>
      $groups
    </div>
    <div>
      $subgroups
    </div>
    <div class="js_panel taxon_selector_form" style="$selector_style">
      <input class="panel_type" value="BlastSpeciesList" type="hidden">
      <div class="list-wrapper">
        <div class="list">$list</div>
        <div class="links"><a class="modal_link data" id="species_selector" href="${modal_uri}">Add/remove species</a></div>
      </div>
      <div class="checkboxes">$checkboxes</div>
    </div>
  };

  my $ele = shift @{$form->get_elements_by_class_name('_species_dropdown')};
  $ele->inner_HTML($html);

  return $form;
}

1;
