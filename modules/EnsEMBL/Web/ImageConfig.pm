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

package EnsEMBL::Web::ImageConfig;

use strict;

sub load_tracks {
  my ($self,$params) = @_;
  my $species      = $self->{'species'};
  my $species_defs = $self->species_defs;
  my $dbs_hash     = $self->databases;

  my %data_types = (
    core => [
      'add_dna_align_features',     # Add to cDNA/mRNA, est, RNA, other_alignment trees
      'add_data_files',             # Add to gene/rnaseq tree
#     'add_ditag_features',         # Add to ditag_feature tree
      'add_genes',                  # Add to gene, transcript, align_slice_transcript, tsv_transcript trees
      'add_trans_associated',       # Add to features associated with transcripts
      'add_marker_features',        # Add to marker tree
      'add_qtl_features',           # Add to marker tree
      'add_genome_attribs',         # Add to genome_attribs tree
      'add_misc_features',          # Add to misc_feature tree
      'add_prediction_transcripts', # Add to prediction_transcript tree
      'add_protein_align_features', # Add to protein_align_feature_tree
      'add_protein_features',       # Add to protein_feature_tree
      'add_repeat_features',        # Add to repeat_feature tree
      'add_simple_features',        # Add to simple_feature tree
      'add_sequence_variations_eva',# ParaSite - add EVA variation tracks, even if we don't have a variation database
      'add_decorations'
    ],
    compara => [
      'add_synteny',                # Add to synteny tree
      'add_alignments'              # Add to compara_align tree
    ],
    funcgen => [
      'add_regulation_builds',      # Add to regulation_feature tree
      'add_regulation_features',    # Add to regulation_feature tree
      'add_oligo_probes'            # Add to oligo tree
    ],
    variation => [
      'add_sequence_variations',          # Add to variation_feature tree
      'add_phenotypes',                   # Add to variation_feature tree
      'add_structural_variations',        # Add to variation_feature tree
      'add_copy_number_variant_probes',   # Add to variation_feature tree
      'add_recombination',                # Moves recombination menu to the end of the variation_feature tree
      'add_somatic_mutations',            # Add to somatic tree
      'add_somatic_structural_variations' # Add to somatic tree
    ],
  );

  foreach my $type (keys %data_types) {
    my ($check, $databases) = $type eq 'compara' ? ($species_defs->multi_hash, $species_defs->compara_like_databases) : ($dbs_hash, $self->sd_call("${type}_like_databases"));

    foreach my $db (grep exists $check->{$_}, @{$databases || []}) {
      my $key = lc substr $db, 9;
      $self->$_($key, $check->{$db}{'tables'} || $check->{$db}, $species,$params) for @{$data_types{$type}}; # Look through tables in databases and add data from each one      
    }
  }

  $self->add_options('information', [ 'opt_empty_tracks', 'Display empty tracks', undef, undef, 'off' ]) unless $self->get_parameter('opt_empty_tracks') eq '0';
  $self->add_options('information', [ 'opt_subtitles', 'Display in-track labels', undef, undef, 'normal' ]);
  $self->add_options('information', [ 'opt_highlight_feature', 'Highlight current feature', undef, undef, 'normal' ]);
  $self->tree->append_child($self->create_option('track_order')) if $self->get_parameter('sortable_tracks');
}

sub menus {
  return $_[0]->{'menus'} ||= {
    # Sequence
    seq_assembly        => 'Sequence and assembly',
    sequence            => [ 'Sequence',          'seq_assembly' ],
    misc_feature        => [ 'Clones',            'seq_assembly' ],
    genome_attribs      => [ 'Genome attributes', 'seq_assembly' ],
    marker              => [ 'Markers',           'seq_assembly' ],
    simple              => [ 'Simple features',   'seq_assembly' ],
    ditag               => [ 'Ditag features',    'seq_assembly' ],
    dna_align_other     => [ 'GRC alignments',    'seq_assembly' ],

    # Transcripts/Genes
    gene_transcript     => 'Genes and transcripts',
    transcript          => [ 'Genes',                  'gene_transcript' ],
    prediction          => [ 'Prediction transcripts', 'gene_transcript' ],
    lrg                 => [ 'LRG transcripts',        'gene_transcript' ],
    rnaseq              => [ 'RNASeq models',          'gene_transcript' ],
## ParaSite
    dna_align_ncrna_pred => [ 'ncRNA Predictions',      'gene_transcript' ],
##
    
## ParaSite
    parasite_rnaseq     => 'RNA-Seq Alignments',
    community_annotation => 'Community Annotation',
##

## EG used to organise fungi/protists external tracks
    chromatin_binding      => 'Chromatin binding',
    pb_intron_branch_point => 'Intron Branch Point',
    polya_sites            => 'Polyadenylation sites',
    replication_profiling  => 'Replication Profiling',
    regulatory_elements    => 'Regulatory Elements',

    transcriptome          => 'Transcriptome',
    nucleosome             => 'Nucleosome Positioning',
    dna_methylation        => 'DNA Methylation',
    histone_mod            => 'Histone Modification',
#       

    # Supporting evidence
    splice_sites        => 'Splice sites',
    evidence            => 'Evidence',

    # Alignments
    mrna_prot           => 'mRNA and protein alignments',
    dna_align_cdna      => [ 'mRNA alignments',    'mrna_prot' ],
    dna_align_est       => [ 'EST alignments',     'mrna_prot' ],
    protein_align       => [ 'Protein alignments', 'mrna_prot' ],
    protein_feature     => [ 'Protein features',   'mrna_prot' ],
    rnaseq_bam          => [ 'RNASeq study',       'mrna_prot' ],
    dna_align_rna       => 'ncRNA',

    # Proteins
    domain              => 'Protein domains',
    gsv_domain          => 'Protein domains',
    feature             => 'Protein features',

    # Variations
    variation           => 'Variation',
    somatic             => 'Somatic mutations',
    ld_population       => 'Population features',

    # Regulation
    functional          => 'Regulation',

    # Compara
    compara             => 'Comparative genomics',
    pairwise_blastz     => [ 'BLASTz/LASTz alignments',    'compara' ],
    pairwise_other      => [ 'Pairwise alignment',         'compara' ],
    pairwise_tblat      => [ 'Translated blat alignments', 'compara' ],
    multiple_align      => [ 'Multiple alignments',        'compara' ],
    conservation        => [ 'Conservation regions',       'compara' ],
    synteny             => 'Synteny',

    # Other features
    repeat              => 'Repeat regions',
    oligo               => 'Oligo probes',
    trans_associated    => 'Transcript features',

    # Info/decorations
    information         => 'Information',
    decorations         => 'Additional decorations',
    other               => 'Additional decorations',

    # External data
    user_data           => 'Your data',
    external_data       => 'External data',
  };
}

sub _add_trackhub {
  my ($self, $menu_name, $url, $is_poor_name, $existing_menu, $force_hide) = @_;

  return ($menu_name, {}) if $self->{'_attached_trackhubs'}{$url};

  my $trackhub  = EnsEMBL::Web::File::Utils::TrackHub->new('hub' => $self->hub, 'url' => $url);
  my $hub_info = $trackhub->get_hub({'assembly_lookup' => $self->species_defs->assembly_lookup, 
                                      'parse_tracks' => 1}); ## Do we have data for this species?
  
  if ($hub_info->{'error'}) {
    ## Probably couldn't contact the hub
    push @{$hub_info->{'error'}||[]}, '<br /><br />Please check the source URL in a web browser.';
  } else {
    my $shortLabel = $hub_info->{'details'}{'shortLabel'};
    $menu_name = $shortLabel if $shortLabel and $is_poor_name;

    my $menu     = $existing_menu || $self->tree->append_child($self->create_submenu($menu_name, $menu_name, { external => 1, trackhub_menu => 1 }));

    my $node;
    my $assemblies = $self->hub->species_defs->get_config($self->species,'TRACKHUB_ASSEMBLY_ALIASES');
    $assemblies ||= [];
    $assemblies = [ $assemblies ] unless ref($assemblies) eq 'ARRAY';
    foreach my $assembly_var (qw(UCSC_GOLDEN_PATH ASSEMBLY_VERSION)) {
      my $assembly = $self->hub->species_defs->get_config($self->species,$assembly_var);
      next unless $assembly;
      push @$assemblies,$assembly;
    }
    foreach my $assembly (@$assemblies) {
      $node = $hub_info->{'genomes'}{$assembly}{'tree'};
      last if $node;
    }
    if ($node) {
      $self->_add_trackhub_node($node, $menu, $menu_name, $force_hide);

      $self->{'_attached_trackhubs'}{$url} = 1;
    } else {
      my $assembly = $self->hub->species_defs->get_config($self->species, 'ASSEMBLY_VERSION');
      $hub_info->{'error'} = ["No sources could be found for assembly $assembly. Please check the hub's genomes.txt file for supported assemblies."];
    }
  }
  return ($menu_name, $hub_info);
}

sub _add_trackhub_tracks {
  my ($self, $parent, $children, $config, $menu, $name) = @_;
  my $hub    = $self->hub;
  my $data   = $parent->data;
  my $matrix = $config->{'dimensions'}{'x'} && $config->{'dimensions'}{'y'};
  my %tracks;

  my %options = (
    menu_key     => $name,
    menu_name    => $name,
    submenu_key  => $self->tree->clean_id("${name}_$data->{'track'}", '\W'),
    submenu_name => $data->{'shortLabel'},
    trackhub      => 1,
  );

  if ($matrix) {
    $options{'matrix_url'} = $hub->url('Config', { action => 'Matrix', function => $hub->action, partial => 1, menu => $options{'submenu_key'} });

    foreach my $subgroup (keys %$config) {
      next unless $subgroup =~ /subGroup\d/;

      foreach (qw(x y)) {
        if ($config->{$subgroup}{'name'} eq $config->{'dimensions'}{$_}) {
          $options{'axis_labels'}{$_} = { %{$config->{$subgroup}} }; # Make a deep copy so that the regex below doesn't affect the subgroup config
          s/_/ /g for values %{$options{'axis_labels'}{$_}};
        }
      }

      last if scalar keys %{$options{'axis_labels'}} == 2;
    }

    $options{'axes'} = { map { $_ => $options{'axis_labels'}{$_}{'label'} } qw(x y) };
  }

  my $submenu = $self->create_submenu($options{'submenu_key'}, $options{'submenu_name'}, {
    external => 1,
    ($matrix ? (
      menu   => 'matrix',
      url    => $options{'matrix_url'},
      matrix => {
        section     => $menu->data->{'caption'},
        header      => $options{'submenu_name'},
        desc_url    => $config->{'description_url'},
        description => $config->{'shortLabel'},
        axes        => $options{'axes'},
      }
    ) : ())
  });

  $self->alphabetise_tracks($submenu, $menu);

  my $count_visible = 0;

  my $style_mappings = {
                        'bigbed' => {
                                      'full'    => 'as_transcript_label',
                                      'pack'    => 'as_transcript_label',
                                      'squish'  => 'half_height',
                                      'dense'   => 'as_alignment_nolabel',
                                      },
                        'bigwig' => {
                                      'full'    => 'signal',
                                      'default' => 'signal',
                                      'dense'   => 'compact',
                                    },
                        'vcf' =>    {
                                      'full'    => 'histogram',
                                      'dense'   => 'compact',
                                    },
                      };

  foreach (@{$children||[]}) {
    my $track        = $_->data;
    my $type         = ref $track->{'type'} eq 'HASH' ? uc $track->{'type'}{'format'} : uc $track->{'type'};
## ParaSite: show bigGenePred as bigBed
    $type =~ s/^BIGGENEPRED$/BIGBED/;
##

    my $on_off = $config->{'on_off'} || $track->{'on_off'} || 'off';  ## ParaSite
    ## Turn track on if there's no higher setting turning it off
    if ($track->{'visibility'}  eq 'hide') {
      $on_off = 'off';
    }
## ParaSite: show the track if visibility is specified - as defined in the UCSC specification
    elsif ($track->{'visibility'} =~ /^full|pack|squish|dense$/) {
      $on_off = 'on';
    }
##
    elsif (!$config->{'on_off'} && !$track->{'on_off'}) {
      $on_off = 'on';
   }

    my $ucsc_display  = $config->{'visibility'} || $track->{'visibility'};

    ## FIXME - According to UCSC's documentation, 'squish' is more like half_height than compact
    my $squish       = $track->{'visibility'} eq 'squish' || $config->{'visibility'} eq 'squish'; # FIXME: make it inherit correctly
## ParaSite: change the way we display the labels
    (my $source_name = $track->{'longLabel'}) =~ s/_/ /g;
## 
    
    ## Translate between UCSC terms and Ensembl ones
    my $default_display = $style_mappings->{lc($type)}{$ucsc_display}
                              || $style_mappings->{lc($type)}{'default'}
                              || 'off';  ## ParaSite: switch off the track by default if no display is given
    $options{'default_display'} = $default_display;

    ## Set track style if appropriate 
    if ($on_off && $on_off eq 'on') {
      $options{'display'} = $default_display;
      $count_visible++;
    }
    else {
      $options{'display'} = 'off';
    }

    my $desc_url = $track->{'description_url'} ? $hub->url('Ajax', {'type' => 'fetch_html', 'url' => $track->{'description_url'}}) : '';

    ## Note that we use a duplicate value in description and longLabel, because non-hub files 
    ## often have much longer descriptions so we need to distinguish the two
    my $source       = {
      name        => $track->{'track'},
      source_name => $source_name,
      desc_url    => $track->{'description_url'},
      description => $desc_url ? qq(<span style="overflow-wrap: break-word" class="_dyna_load"><a class="hidden" href="$desc_url">$track->{'longLabel'}</a>Loading &#133;</span>) : '',
      longLabel   => $track->{'longLabel'},
      caption     => $track->{'shortLabel'},
      source_url  => $track->{'bigDataUrl'},
      colour      => exists $track->{'color'} ? $track->{'color'} : undef,
      colorByStrand => exists $track->{'colorByStrand'} ? $track->{'colorByStrand'} : undef,
      spectrum    => exists $track->{'spectrum'} ? $track->{'spectrum'} : undef,
      no_titles   => $type eq 'BIGWIG', # To improve browser speed don't display a zmenu for bigwigs
      squish      => $squish,
      signal_range => $track->{'signal_range'},
      %options
    };

    # Graph range - Track Hub default is 0-127

    if (exists $track->{'viewLimits'}) {
      $source->{'viewLimits'} = $track->{'viewLimits'};
    } elsif ($track->{'autoScale'} eq 'off') {
      $source->{'viewLimits'} = '0:127';
    }

    if (exists $track->{'maxHeightPixels'}) {
      $source->{'maxHeightPixels'} = $track->{'maxHeightPixels'};
    } elsif ($type eq 'BIGWIG' || $type eq 'BIGBED') {
## ParaSite: change height of tracks
      $source->{'maxHeightPixels'} = '60:60:60';
## ParaSite
    }

    if ($matrix) {
      my $caption = $track->{'shortLabel'};
      $source->{'section'} = $parent->data->{'shortLabel'};
      ($source->{'source_name'} = $track->{'longLabel'}) =~ s/_/ /g;
      $source->{'labelcaption'} = $caption;

      $source->{'matrix'} = {
        menu   => $options{'submenu_key'},
        column => $options{'axis_labels'}{'x'}{$track->{'subGroups'}{$config->{'dimensions'}{'x'}}},
        row    => $options{'axis_labels'}{'y'}{$track->{'subGroups'}{$config->{'dimensions'}{'y'}}},
      };

      $source->{'column_data'} = { desc_url => $config->{'description_url'}, description => $config->{'shortLabel'}, no_subtrack_description => 1 };
    }

    $tracks{$type}{$source->{'name'}} = $source;
  }

  $self->load_file_format(lc, $tracks{$_}) for keys %tracks;
}

sub _update_missing {
  my ($self, $object) = @_;
  my $species_defs    = $self->species_defs;
  my $count_missing   = grep { $_->get('display') eq 'off' || !$_->get('display') } $self->get_tracks;
  my $missing         = $self->get_node('missing');

  $missing->set('extra_height', 4) if $missing;
  $missing->set('text', $count_missing > 0 ? "There are currently $count_missing tracks turned off." : 'All tracks are turned on') if $missing;

## ParaSite: do not display the Ensembl version number
  my $info = sprintf(
    '%s %s: %s (%s).%s Region: %s:%s-%s',
    $species_defs->ENSEMBL_SITETYPE,
    $species_defs->SITE_RELEASE_VERSION,
    $species_defs->SPECIES_BIO_NAME,
    $species_defs->SPECIES_BIOPROJECT,
    $species_defs->ASSEMBLY_ACCESSION ? sprintf(" Assembly: %s (%s).", $species_defs->ASSEMBLY_NAME, $species_defs->ASSEMBLY_ACCESSION) : sprintf(" Assembly: %s.", $species_defs->ASSEMBLY_NAME),
    $object->seq_region_type_and_name,
    $object->thousandify($object->seq_region_start),
    $object->thousandify($object->seq_region_end)
  );
## ParaSite

  my $information = $self->get_node('info');
  $information->set('text', $info) if $information;
  $information->set('extra_height', 2) if $information;

  return { count => $count_missing, information => $info };
}

sub add_sequence_variations_eva {
  my ($self, $key, $hashref) = @_;
  return if $key ne 'core';
  
  my $menu = $self->get_node('variation');
  return unless $menu;

  my $options = {
    db         => $key,
    glyphset   => '_eva',
    strand     => 'r',
    depth      => 0.5,
    bump_width => 0,
    colourset  => 'variation',
    display    => 'off',
    renderers  => [ 'off', 'Off', 'compact', 'Collapsed' ],
  };
 
  $self->add_sequence_variations_default_eva($key, $hashref, $options);
 
  $self->add_track('information', 'variation_legend', 'Variant Legend', 'variation_legend', { strand => 'r' });
  
}

sub add_sequence_variations_default_eva {
  my ($self, $key, $hashref, $options) = @_;
  my $menu = $self->get_node('variation');
  my $sequence_variation = ($menu->get_node('variants')) ? $menu->get_node('variants') : $self->create_submenu('variants', 'Sequence variants');

  return unless $self->hub->species_defs->EVA_TRACKS;

  foreach my $study (@{$self->hub->species_defs->EVA_TRACKS}) {
    my $title = $study->{'name'};
    my $name  = "variation_feature_eva_" . $study->{'study_id'};
    $sequence_variation->append($self->create_track($name, $title, {
      %$options,
      caption     => $study->{'study_id'} . " Variations",
      sources     => undef,
      study_id    => $study->{'study_id'},
      eva_species => $study->{'eva_species'},
      display     => 'compact',
      description => sprintf('%s<br />Variants loaded from study <a href="%s/?eva-study=%s">%s</a> in the European Variation Archive.',
                             $study->{'description'},
                             $self->hub->species_defs->EVA_URL,
                             $study->{'study_id'},
                             $study->{'study_id'}),
    }));
  }
  
  $menu->append($sequence_variation);

}

1;
