package EnsEMBL::Web::ImageConfigExtension::Tracks;

package EnsEMBL::Web::ImageConfig;

use strict;
use warnings;

sub load_tracks {
  my ($self,$params) = @_;
  my $species      = $self->species;
  my $species_defs = $self->species_defs;
  my $dbs_hash     = $self->databases;

  my %methods_for_dbtypes = (
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

  foreach my $db_type (keys %methods_for_dbtypes) {
    my ($db_hash, $databases) = $db_type eq 'compara'
      ? ($species_defs->multi_hash, $species_defs->compara_like_databases)
      : ($dbs_hash, $species_defs->get_config($species, "${db_type}_like_databases"));

    # For all the dbs belonging to a particular db type, call all the methods, one be one, to add tracks for that db type
    foreach my $db_key (grep exists $db_hash->{$_}, @{$databases || []}) {
      my $db_name = lc substr $db_key, 9;

      foreach my $method (@{$methods_for_dbtypes{$db_type}}) {
        $self->$method($db_name, $db_hash->{$db_key}{'tables'} || $db_hash->{$db_key}, $species, @_);
      }
    }
  }

  $self->add_options('information', [ 'opt_empty_tracks', 'Display empty tracks', 'off' ]) unless $self->get_parameter('opt_empty_tracks') eq '0';
  $self->add_options('information', [ 'opt_subtitles', 'Display in-track labels', 'normal' ]);
  $self->add_options('information', [ 'opt_highlight_feature', 'Highlight current feature', 'normal' ]);
  $self->tree->root->append_child($self->create_option('track_order')) if $self->get_parameter('sortable_tracks');
}

1;