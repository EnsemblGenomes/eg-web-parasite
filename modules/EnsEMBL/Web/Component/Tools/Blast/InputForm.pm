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

package EnsEMBL::Web::Component::Tools::Blast::InputForm;

use strict;
use warnings;

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $options   = $self->object->get_blast_form_options->{'options'};
  my $form      = $self->new_tool_form({'class' => 'blast-form'});
  my $fieldset  = $form->add_fieldset;
  my $has_seqid = $hub->species_defs->ENSEMBL_BLAST_BY_SEQID;

  my $query_seq_field = $fieldset->add_field({
    'label'           => 'Sequence data',
    'field_class'     => '_adjustable_height',
    'helptip'         => $has_seqid
                            ? 'Enter sequence as plain text or in FASTA format, or enter a sequence ID or accession from EnsEMBL, EMBL, UniProt or RefSeq'
                            : 'Enter sequence as plain text or in FASTA format',
    'elements'        => [{
      'type'            => 'div',  # container used by js for adding sequence divs
      'element_class'   => '_sequence js_sequence_wrapper hidden',
    }, {
      'type'            => 'div',  # other sequence input elements will get wrapped in this one later
      'element_class'   => '_sequence_field',
      'children'        => [{'node_name' => 'div', 'class' => 'query_sequence_wrapper'}]
    }, {
      'type'            => 'text',
      'value'           =>  sprintf('Maximum of %s sequences (%s)', MAX_NUM_SEQUENCES, $has_seqid ? 'type in plain text, FASTA or sequence ID' : 'type in plain text or FASTA'),
      'class'           => 'inactive query_sequence',
      'name'            => 'query_sequence',
    }, {
      'type'            => 'noedit',
      'value'           => 'Or upload sequence file',
      'no_input'        => 1,
      'element_class'   => 'file_upload_element'
    }, {
      'type'            => 'file',
      'name'            => 'query_file',
      'element_class'   => 'file_upload_element'
    }, {
      'type'            => 'radiolist',
      'name'            => 'query_type',
      'values'          => $options->{'query_type'},
    }]
  });
  my $query_seq_elements = $query_seq_field->elements;

  # add a close button to the textarea element
  $query_seq_elements->[2]->prepend_child('span', {'class' => 'sprite cross_icon _ht', 'title' => 'Cancel'});

  # wrap the sequence input elements
  $query_seq_elements->[1]->first_child->append_children(map { $query_seq_elements->[$_]->remove_attribute('class', $query_seq_field->CSS_CLASS_ELEMENT_DIV); $query_seq_elements->[$_]; } 2..4);

  my $species_defs    = $hub->species_defs;
  my $default_species = $hub->species || 'Multi';

  my @species         = $hub->param('species') || $default_species || ();

#  my $modal_uri       = $hub->url('Component', {qw(type Tools action Blast function TaxonSelector/ajax)});
  my $modal_uri       = $hub->url('MultiSelector', {
                          qw(type Tools action Blast function TaxonSelector),
                          s => $default_species,
                          multiselect => 1
                        });

## ParaSite: add in our species grouping

  my $url_species = $species_defs->valid_species($default_species) ? $default_species : 'Multi';

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
  foreach my $group (keys %{$species_defs->TAXON_MULTI}) {
    map($lookup{$_} = $group, @{$species_defs->TAXON_MULTI->{$group}});
  }
  foreach my $sp ($species_defs->valid_species) {
    $groups .= sprintf('<input type="hidden" name="species_taxon" value="%s" class="%s %s" />', $sp, $species_defs->get_config($sp, 'SPECIES_GROUP'), $lookup{$species_defs->get_config($sp, 'SPECIES_SUBGROUP')} || $species_defs->get_config($sp, 'SPECIES_SUBGROUP')),
  }

  # Populathe the species checkboxes with everything if no species selected
  my $list = join '', map { '<li>' . $self->getSpeciesDisplayHtml($_) . '</li>' } @species;
  my $checkboxes;
  if($url_species eq 'Multi') {
    $checkboxes = join '<br />', map { sprintf('<input type="checkbox" name="species" value="%s" checked>%s', $_, $_) } $species_defs->valid_species;
  } else {
    $checkboxes = join '<br />', map { sprintf('<input type="checkbox" name="species" value="%s" checked>%s', $_, $_) } @species;
  }

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

  my $species_select  = $form->append_child('div', {
    'class'       => 'ff-right',
    'wrapper_class' => '_species_dropdown',
    'children'    => [{
      'node_name' => 'div',
      'inner_HTML' => $html,
    }]
  });
##

  my $search_against_field = $fieldset->add_field({
    'label'           => 'Search against',
    'field_class'     => '_adjustable_height',
  });
  $search_against_field->append_child($species_select);

  for (@{$options->{'db_type'}}) {

    $search_against_field->add_element({
      'type'            => 'radiolist',
      'name'            => 'db_type',
      'element_class'   => 'blast_db_type',
      'values'          => [ $_ ],
      'inline'          => 1
    });

    $search_against_field->add_element({
      'type'            => 'dropdown',
      'name'            => "source_$_->{'value'}",
      'element_class'   => 'blast_source',
      'values'          => $options->{'source'}{$_->{'value'}},
      'inline'          => 1
    });
  }

  $fieldset->add_field({
    'label'           => 'Search tool',
    'elements'        => [{
      'type'            => 'dropdown',
      'name'            => 'search_type',
      'class'           => '_stt',
      'values'          => $options->{'search_type'}
    }]
  });

  # Search sensitivity config sets
  my @sensitivity_elements;
  my @field_classes;
  my ($config_options, $all_config_sets) = CONFIGURATION_SETS;

  for (@{$options->{'search_type'}}) {

    my $search_type = $_->{'value'};

    if (my $config_sets = $all_config_sets->{$search_type}) {

      push @sensitivity_elements, {
        'type'          => 'dropdown',
        'name'          => "config_set_$search_type",
        'element_class' => "_stt_$search_type",
        'values'        => [ grep { $config_sets->{$_->{'value'}} } @$config_options ]
      };
      push @field_classes, "_stt_$search_type";
    }
  }

  if (@sensitivity_elements) {
    $fieldset->add_field({
      'label'       => 'Search Sensitivity:',
      'elements'    => \@sensitivity_elements,
      'field_class' => \@field_classes
    });
  }

  $fieldset->add_field({
    'label'           => 'Description (optional):',
    'type'            => 'string',
    'name'            => 'description',
  });

  # Advanced config options
  $form->add_fieldset;

  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;
   
  my @search_types    = map $_->{'value'}, @{$options->{'search_type'}};
  my %stt_classes     = map {$_ => "_stt_$_"} @search_types; # class names for selectToToggle

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {

    my $config_fieldset = $form->add_fieldset;

    my %wrapper_class;

    while (my ($element_name, $element_params) = splice @{$config_field_group->{'fields'}}, 0, 2) {
      my $field_params = { map { exists $element_params->{$_} ? ($_ => delete $element_params->{$_}) : () } qw(field_class label helptip notes head_notes inline) };
      $field_params->{'elements'} = [];

      my %field_class;

      ## add one element for each with its own default value for each valid search type
      foreach my $search_type_value (@search_types) {        
        for ($search_type_value, 'all') {            
          if (exists $config_defaults->{$_}{$element_name}) {       
            my $element_class = $stt_classes{$search_type_value};       
            
            if(defined $element_params->{elements}) {        
              for my $el (@{$element_params->{elements}}) {
                push @{$field_params->{'elements'}}, {
                  'name'          => "${search_type_value}__$el->{name}",
                  'values'        => $el->{values},                  
                  'class'         => $el->{class},
                  'value'         => $config_defaults->{$_}{$element_name},
                  'element_class' => $el->{element_class}." $element_class",
                  'type'          => $el->{type}
                };
              }              
            } else { 
              push @{$field_params->{'elements'}}, {
                %{$self->deepcopy($element_params)},
                'name'          => "${search_type_value}__${element_name}",
                'value'         => $config_defaults->{$_}{$element_name},
                'element_class' => $element_class
              };
            }
           
            $field_class{$element_class}    = 1; # adding same class to the field makes sure the field is only visible if at least one of the elements is visible            
            $wrapper_class{$element_class}  = 1; # adding same class to the config wrapper div makes sure the div is only visible if at least one of the field is visible

            last;
          }
        }
      }

      my $field = $config_fieldset->add_field($field_params);
      $field->set_attribute('class', [ keys %field_class ]) unless keys %field_class == keys %stt_classes; # if all classes are there, this field is actually never hidden.
    }

    $self->togglable_fieldsets($form, {
      'class' => scalar keys %wrapper_class == scalar keys %stt_classes ? [] : [ keys %wrapper_class ], # if all classes are there, the wrapper div is actually never hidden.
      'title' => ucfirst "$config_type options" =~ s/_/ /gr,
      'desc'  => $config_field_group->{'caption'}
    }, $config_fieldset);
  }

  # Buttons in a new fieldset
  $self->add_buttons_fieldset($form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  return $form;
}

sub getSpeciesDisplayHtml {
  my $self = shift;
  my $species = shift;
  my $common_name = $species eq 'Multi' ? '' : $self->hub->species_defs->get_config($species, 'SPECIES_COMMON_NAME');
  return $common_name . '<br />';
}

1;
