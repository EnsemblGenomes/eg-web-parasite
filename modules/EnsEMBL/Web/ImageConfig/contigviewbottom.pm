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

package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ImageConfig);

sub init_cacheable {
  my $self = shift;
  
  $self->SUPER::init_cacheable(@_);
  
  $self->set_parameters({
    image_resizeable => 1,
    bottom_toolbar   => 1,
    sortable_tracks  => 'drag', # allow the user to reorder tracks on the image
    can_trackhubs    => 1,      # allow track hubs
    opt_halfheight   => 0,      # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_lines        => 1,      # draw registry lines
  });
  
  # First add menus in the order you want them for this display
  $self->create_menus(qw(
    sequence
    marker
    trans_associated
    transcript
    prediction
    lrg
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    dna_align_ncrna_pred
    parasite_rnaseq
    community_annotation
    protein_align
    protein_feature
    rnaseq
    ditag
    simple
    genome_attribs
    misc_feature
    variation
    recombination
    somatic
    functional
    multiple_align
    conservation
    pairwise_blastz
    pairwise_tblat
    pairwise_other
    dna_align_compara
    oligo
    repeat
    external_data
    user_data
    decorations
    information
  ));
  
  my %desc = (
    contig    => 'Track showing underlying assembly contigs.',
    seq       => 'Track showing sequence in both directions. Only displayed at 1Kb and below.',
    codon_seq => 'Track showing 6-frame translation of sequence. Only displayed at 500bp and below.',
    codons    => 'Track indicating locations of start and stop codons in region. Only displayed at 50Kb and below.'
  );
  
  # Note these tracks get added before the "auto-loaded tracks" get added
  $self->add_tracks('sequence', 
    [ 'contig',    'Contigs',             'contig',   { display => 'normal', strand => 'r', description => $desc{'contig'}                                                                }],
    [ 'seq',       'Sequence',            'sequence', { display => 'normal', strand => 'b', description => $desc{'seq'},       colourset => 'seq',      threshold => 1,   depth => 1      }],
    [ 'codon_seq', 'Translated sequence', 'codonseq', { display => 'off',    strand => 'b', description => $desc{'codon_seq'}, colourset => 'codonseq', threshold => 0.5, bump_width => 0 }],
    [ 'codons',    'Start/stop codons',   'codons',   { display => 'off',    strand => 'b', description => $desc{'codons'},    colourset => 'codons',   threshold => 50                   }],
  );
  
  $self->add_track('decorations', 'gc_plot', '%GC', 'gcplot', { display => 'normal',  strand => 'r', description => 'Shows percentage of Gs & Cs in region', sortable => 1 });
  
  # Add in additional tracks
  $self->load_tracks;
  $self->load_configured_trackhubs;
  $self->load_configured_bigwig;
  $self->load_configured_bigbed;
#  $self->load_configured_bam;

  #switch on some variation tracks by default
  if ($self->species_defs->DEFAULT_VARIATION_TRACKS) {
    while (my ($track, $style) = each (%{$self->species_defs->DEFAULT_VARIATION_TRACKS})) {
      $self->modify_configs([$track], {display => $style});
    }
  }
  elsif ($self->hub->database('variation')) {
    my $tracks = [qw(variation_feature_variation)];
    if ($self->species_defs->databases->{'DATABASE_VARIATION'}{'STRUCTURAL_VARIANT_COUNT'}) {
      push @$tracks, 'variation_feature_structural_smaller';
    }
    $self->modify_configs($tracks, {display => 'compact'});
  }

  ## ParaSite: display the EVA tracks by default
  if($self->hub->species_defs->EVA_TRACKS) {
    foreach my $study (@{$self->hub->species_defs->EVA_TRACKS}) {
      my $track  = "variation_feature_eva_" . $study->{'study_id'};
      $self->modify_configs([$track], {display => 'compact'});
    }
  }
  ##
  
  $self->add_tracks('information',
    [ 'missing', '', 'text', { display => 'normal', strand => 'r', name => 'Disabled track summary', description => 'Show counts of number of tracks turned off by the user' }],
    [ 'info',    '', 'text', { display => 'normal', strand => 'r', name => 'Information',            description => 'Details of the region shown in the image' }]
  );
  
  $self->add_tracks('decorations',
    [ 'scalebar',  '', 'scalebar',  { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',     { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable', { display => 'normal', strand => 'b', menu => 'no' }]
  );
  
  ## Switch on multiple alignments defined in MULTI.ini
  my $compara_db      = $self->hub->database('compara');
  if ($compara_db) {
    my $mlss_adaptor    = $compara_db->get_adaptor('MethodLinkSpeciesSet');
    my %alignments      = $self->species_defs->multiX('COMPARA_DEFAULT_ALIGNMENTS');
    my $defaults = $self->hub->species_defs->multi_hash->{'DATABASE_COMPARA'}->{'COMPARA_DEFAULT_ALIGNMENT_IDS'};

    foreach my $default (@$defaults) {
      my ($mlss_id,$species,$method) = @$default;
      $self->modify_configs(
        [ 'alignment_compara_'.$mlss_id.'_constrained' ],
        { display => 'compact' }
      );
    }
  }

## ParaSite
  $self->modify_configs( ['dna_align_ncrna_pred'], {'display'=>'as_alignment_label'} );
  $self->modify_configs( ['parasite_rnaseq'], {'strand'=>'r'} );
##

}

1;

