package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;
use warnings;

use previous qw(init initialize);


sub init {
  my $self = shift;

  $self->create_menus(qw(
    sequence
    marker
    trans_associated
    transcript
    prediction
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    protein_align
    protein_feature
    rnaseq
    parasite_rnaseq
    ERP001209
    ERP001238
    ERP004459
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

    chromatin_binding
    pb_intron_branch_point
    polya_sites 
    replication_profiling
    regulatory_elements
    transcriptome
    nucleosome
    dna_methylation
    histone_mod 

    external_data
    user_data
    decorations
    information
  ));

  $self->PREV::init(@_);

  $self->modify_configs( ['parasite_rnaseq'], {'display'=>'tiling'} );

}

1;

