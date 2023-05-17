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

package EnsEMBL::Web::Component::Tools::VEP::InputForm;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::VEPConstants qw(INPUT_FORMATS CONFIG_SECTIONS);

use parent qw(
  EnsEMBL::Web::Component::Tools::VEP
  EnsEMBL::Web::Component::Tools::InputForm
);


sub get_cacheable_form_node {


  ## Abstract method implementation
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $sd              = $hub->species_defs;
  my $species         = $object->species_list;
  my $form            = $self->new_tool_form;
  my $fd              = $object->get_form_details;
  my $input_formats   = INPUT_FORMATS;


 my $input_fieldset = $form->add_fieldset({'class' => @$species <= 100 ? '' : 'long_species_fieldset' , 'no_required_notes' => 1});

  

  #####EG Start - Adding AJAX type species selector to VEP form#######

  # Species dropdown list with stt classes to dynamically toggle other fields
  if ( @$species <= 100 ) {
    $input_fieldset->add_field({
      'label'         => 'Species',
      'elements'      => [{
        'type'          => 'speciesdropdown',
        'name'          => 'species',
        'values'        => [ map {
          'value'         => $_->{'value'},
          'caption'       => $_->{'caption'},
          'class'         => [  #selectToToggle classes for JavaScript
            '_stt', '_sttmulti',
            $_->{'variation'}             ? '_stt__var'   : '_stt__novar',
            $_->{'refseq'}                ? '_stt__rfq'   : (),
            $_->{'variation'}{'POLYPHEN'} ? '_stt__pphn'  : (),
            $_->{'variation'}{'SIFT'}     ? '_stt__sift'  : ()
          ]
        }, @$species ]
      }, {
        'type'          => 'noedit',
        'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s _vep_assembly" rel="%s">%s</span>', $_->{'value'}, $_->{'assembly'}, $_->{'assembly'} } @$species),
        'no_input'      => 1,
        'is_html'       => 1
      }]
    });
  }
  else {
    $input_fieldset->add_field({
      'label' => 'Species',
      'field_class' => 'long_species_field',
       'elements' => [{
         'type'   => 'DropDown',
         'class'  => 'ajax-species-selector',
         'name'   => 'species',
         'values' => [{
           'value' => $hub->data_species,
           'caption' => $hub->data_species =~ /^Multi$/ ? 'Select a species' : sprintf('%s (%s%s)', $sd->get_config($hub->data_species, 'SPECIES_SCIENTIFIC_NAME'), $sd->get_config($hub->data_species, 'SPECIES_BIOPROJECT'), $sd->get_config($hub->data_species, 'SPECIES_STRAIN') ? ' - ' . $sd->get_config($hub->data_species, 'SPECIES_STRAIN') : '')
          }]
        }]
    });
  }
  
 #####EG End#####


 

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this data (optional)'
  });

  
  $input_fieldset->add_field({
    'label'         => 'Either paste data',
    'elements'      => [{
      'type'          => 'text',
      'name'          => 'text',
      'class'         => 'vep-input',
    }, {
      'type'          => 'noedit',
      'noinput'       => 1,
      'is_html'       => 1,
      'caption'       => sprintf('<span class="small" style="font-weight: bold">Examples:&nbsp;%s</span>',
        join(', ', map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$input_formats)
      )
## ParaSite: remove the preview button
    }
  ]});
##

  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Or upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'VEP'} / (1024 * 1024))
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Or provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });

  # This field is shown only for the species having refseq data
  if (first { $_->{'refseq'} } @$species) {
    $input_fieldset->add_field({
      'field_class'   => '_stt_rfq',
      'type'          => 'radiolist',
      'name'          => 'core_type',
      'label'         => $fd->{core_type}->{label},
      'helptip'       => $fd->{core_type}->{helptip},
      'value'         => 'core',
      'class'         => '_stt',
      'values'        => $fd->{core_type}->{values}
    });
    
    $input_fieldset->add_field({
      'field_class'   => '_stt_rfq _stt_merged _stt_refseq',
      'type'    => 'checkbox',
      'name'    => "all_refseq",
      'label'   => $fd->{all_refseq}->{label},
      'helptip' => $fd->{all_refseq}->{helptip},
      'value'   => 'yes',
      'checked' => 0
    });
  }

  ## Output options header
  $form->add_fieldset({'no_required_notes' => 1});

  ### Advanced config options
  my $sections = CONFIG_SECTIONS;
  foreach my $section (@$sections) {

    $self->togglable_fieldsets($form, {
      'title' => $section->{'title'},
      'desc'  => $section->{'caption'}
    }, $self->can('_build_'.$section->{'id'})->($self, $form));
  }

  # Run/Close buttons
  $self->add_buttons_fieldset($form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  return $form;

}

sub _build_identifiers {
  my ($self, $form) = @_;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $species   = $object->species_list;
  my $fd        = $object->get_form_details;

  my @fieldsets;

  ## IDENTIFIERS
  my $current_section = 'Identifiers';
  my $fieldset        = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'symbol',
    'label'       => $fd->{symbol}->{label},
    'helptip'     => $fd->{symbol}->{helptip},
    'value'       => 'yes',
    'checked'     => 1
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_merged _stt_gencode_basic',
    'type'        => 'checkbox',
    'name'        => 'ccds',
    'label'       => $fd->{ccds}->{label},
   'helptip'     => $fd->{ccds}->{helptip},
    'value'       => 'yes',
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'protein',
    'label'       => $fd->{protein}->{label},
    'helptip'     => $fd->{protein}->{helptip},
    'value'       => 'yes'
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'uniprot',
    'label'       => $fd->{uniprot}->{label},
    'helptip'     => $fd->{uniprot}->{helptip},
    'value'       => 'yes'
  });

## ParaSite: disable HGVS option
#  $fieldset->add_field({
#    'type'        => 'checkbox',
#    'name'        => 'hgvs',
#    'label'       => $fd->{hgvs}->{label},
#    'helptip'     => $fd->{hgvs}->{helptip},
#    'value'       => 'yes'
#  });
##

  $self->_end_section(\@fieldsets, $fieldset, $current_section);

  ## FREQUENCY DATA
  # only for the species that have variants
  $current_section = 'Frequency data';
  if ((first { $_->{'variation'} } @$species) || scalar @{$self->_get_plugins_by_section($current_section)}) {
    $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

    $fieldset->add_field({
      'field_class' => '_stt_var',
      'label'       => $fd->{check_existing}->{label},
      'helptip'     => $fd->{check_existing}->{helptip},
      'type'        => 'dropdown',
      'name'        => "check_existing",
      'value'       => 'yes',
      'class'       => '_stt',
      'values'      => $fd->{check_existing}->{values}
    });

    $fieldset->append_child('div', {
      'class'         => '_stt_Homo_sapiens',
      'children'      => [$fieldset->add_field({
        'type'          => 'checklist',
        'label'         => 'Frequency data for co-located variants',
       'field_class'   => [qw(_stt_yes _stt_allele)],
        'values'        => [{
          'name'          => "af",
          'caption'       => $fd->{af}->{label},
          'helptip'       => $fd->{af}->{helptip},
          'value'         => 'yes',
          'checked'       => 1
        }, {
          'name'          => "af_1kg",
          'caption'       => $fd->{af_1kg}->{label},
          'helptip'       => $fd->{af_1kg}->{helptip},
          'value'         => 'yes',
          'checked'       => 0
        }, {
          'name'          => "af_esp",
          'caption'       => $fd->{af_esp}->{label},
          'helptip'       => $fd->{af_esp}->{helptip},
          'value'         => 'yes',
          'checked'       => 0
        }, {
          'name'          => "af_exac",
          'caption'       => $fd->{af_exac}->{label},
          'helptip'       => $fd->{af_exac}->{helptip},
          'value'         => 'yes',
          'checked'       => 0
        }]
      }), $fieldset->add_field({
        'type' => 'checkbox',
        'name' => 'pubmed',
        'label' => $fd->{pubmed}->{label},
        'helptip' => $fd->{pubmed}->{helptip},
        'value' => 'yes',
        'checked' => 1,
        'field_class'   => [qw(_stt_yes _stt_allele)],
      }), $fieldset->add_field({
        'type' => 'checkbox',
        'name' => 'failed',
        'label' => $fd->{failed}->{label},
        'helptip' => $fd->{failed}->{helptip},
        'value' => 1,
        'checked' => 0,
        'field_class'   => [qw(_stt_yes _stt_allele)],
      })]
    });

    $self->_end_section(\@fieldsets, $fieldset, $current_section);
  }

  $self->_plugin_footer($fieldset) if $self->_have_plugins;

  return @fieldsets;
}

sub _build_additional_annotations {
  my ($self, $form) = @_;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $sd        = $hub->species_defs;
  my $species   = $object->species_list;
  my $fd        = $object->get_form_details;

  my @fieldsets;

  ## TRANSCRIPT ANNOTATION SECTION
  my $current_section = 'Transcript annotation';
  my $fieldset  = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'biotype',
    'label'       => $fd->{biotype}->{label},
    'helptip'     => $fd->{biotype}->{helptip},
    'value'       => 'yes',
    'checked'     => 1
  });

  $fieldset->add_field({
    'type'        => 'checkbox',
    'name'        => 'numbers',
    'label'       => $fd->{numbers}->{label},
    'helptip'     => $fd->{numbers}->{helptip},
    'value'       => 'yes',
    'checked'     => 0
  });

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged _stt_Homo_sapiens',
    'type'        => 'checkbox',
    'name'        => 'tsl',
    'label'       => $fd->{tsl}->{label},
    'helptip'     => $fd->{tsl}->{helptip},
    'value'       => 'yes',
    'checked'     => 1,
  }) if (first { $_->{'value'} eq 'Homo_sapiens' } @$species);

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged _stt_Homo_sapiens',
    'type'        => 'checkbox',
    'name'        => 'appris',
    'label'       => $fd->{appris}->{label},
    'helptip'     => $fd->{appris}->{helptip},
    'value'       => 'yes',
    'checked'     => 1,
  }) if (first { $_->{'value'} eq 'Homo_sapiens' } @$species);

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged _stt_Homo_sapiens',
    'type'        => 'checkbox',
    'name'        => 'mane',
    'label'       => $fd->{mane}->{label},
    'helptip'     => $fd->{mane}->{helptip},
    'value'       => 'yes',
    'checked'     => 1,
  }) if (first { $_->{'value'} eq 'Homo_sapiens' } @$species);

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'canonical',
    'label'       => $fd->{canonical}->{label},
    'helptip'     => $fd->{canonical}->{helptip},
    'value'       => 'yes',
    'checked'     => 0,
  });

  $fieldset->add_field({
    'type'        => 'string',
    'name'        => 'distance',
    'label'       => $fd->{distance}->{label},
    'helptip'     => $fd->{distance}->{helptip},
    'value'       => $fd->{distance}->{value},
    'checked'     => 0,
  });

  $self->_end_section(\@fieldsets, $fieldset, $current_section);


  ## PROTEIN ANNOTATION SECTION
  $current_section = 'Protein annotation';
  $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1});

  $fieldset->add_field({
    'field_class' => '_stt_core _stt_gencode_basic _stt_merged',
    'type'        => 'checkbox',
    'name'        => 'domains',
    'label'       => $fd->{domains}->{label},
    'helptip'     => $fd->{domains}->{helptip},
    'value'       => 'yes',
    ## ParaSite: enable this checkbox by default
    'checked'     => 1,
    ##
  });

  $self->_end_section(\@fieldsets, $fieldset, $current_section);


  ## REGULATORY DATA
  $current_section = 'Regulatory data';
  my @regu_species = map { $_->{'value'} } grep {$hub->get_adaptor('get_EpigenomeAdaptor', 'funcgen', $_->{'value'})} grep {$_->{'regulatory'}} @$species;

  if(@regu_species) {
    my @regu_species_classes = map { "_stt_".$_ } @regu_species;

    my $regu_class = (scalar(@regu_species_classes)) ? join(' ',@regu_species_classes) : '';

    $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1, class => $regu_class});

    for (@regu_species) {
      # get available cell types
      my $regulatory_build_adaptor = $hub->get_adaptor('get_RegulatoryBuildAdaptor', 'funcgen', $_);
      my $regulatory_build = $regulatory_build_adaptor->fetch_current_regulatory_build;
      my @cell_types = ();
      foreach (sort {$a->short_name cmp $b->short_name} @{$regulatory_build->get_all_Epigenomes}) {
        my $short_name = $_->short_name;
        my $rm_white_space_label = $short_name;
        $rm_white_space_label =~ s/ /\_/g;
        push @cell_types, { value => $rm_white_space_label, caption => $short_name };
      }

      $fieldset->add_field({
        'field_class'   => "_stt_$_",
        'label'         => $fd->{regulatory}->{label},
        'helptip'       => $fd->{regulatory}->{helptip},
        'elements'      => [{
          'type'          => 'dropdown',
          'name'          => "regulatory_$_",
          'class'         => '_stt',
          'value'         => 'reg',
          'values'        => [
            { 'value'       => 'no',   'caption' => 'No'                                                      },
            { 'value'       => 'reg',  'caption' => 'Yes'                                                     },
            { 'value'       => 'cell', 'caption' => 'Yes and limit by cell type', 'class' => "_stt__cell_$_"  }
          ]
        }, {
          'type'          => 'noedit',
          'caption'       => $fd->{cell_type}->{helptip},
          'no_input'      => 1,
          'element_class' => "_stt_cell_$_"
        }, {
          'element_class' => "_stt_cell_$_",
          'type'          => 'dropdown',
          'multiple'      => 1,
          'label'         => $fd->{cell_type}->{label},
          'name'          => "cell_type_$_",
          'values'        => [ map { 'value' => $_->{value}, 'caption' => $_->{caption} }, @cell_types ]
        }]
      });
    }

    $self->_end_section(\@fieldsets, $fieldset, $current_section);
  }

  ## PHENOTYPE DATA
  my @phen_species = map { $_->{'value'} } grep {$_->{'phenotypes'} } @$species;

  if(@phen_species) {
    my @phen_species_classes = map { "_stt_".$_ } @phen_species;

    my $phen_class = (scalar(@phen_species_classes)) ? join(' ',@phen_species_classes) : '';

    $current_section = 'Phenotype data and citations';
    $fieldset = $form->add_fieldset({'legend' => $current_section, 'no_required_notes' => 1, class => $phen_class});
    $self->_end_section(\@fieldsets, $fieldset, $current_section);
  }

  return @fieldsets;
}

sub _plugin_footer {
  my ($self, $fieldset) = @_;

  return;
}

1;
