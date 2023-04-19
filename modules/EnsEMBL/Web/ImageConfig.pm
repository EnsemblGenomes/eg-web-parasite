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

package EnsEMBL::Web::ImageConfig;

use strict;

sub menus {
  my $species_defs    = $_[0]->species_defs;
 
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
    compara             => 'Pairwise whole genome alignments',
    pairwise_blastz     => [ 'BLASTz/LASTz alignments',    'compara' ],
    pairwise_other      => [ 'Pairwise alignment',         'compara' ],
    pairwise_tblat      => [ 'Translated blat alignments', 'compara' ],
#    multiple_align      => [ 'Multiple alignments',        'compara' ],
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
    external_data       => defined $species_defs->EXTDATA ? $species_defs->EXTDATA->{caption} : 'External Data',
  };
}

sub _update_missing {
  my ($self, $object) = @_;
  my $species_defs    = $self->species_defs;
  my $count_missing   = grep { !$_->get('display') || $_->get('display') eq 'off' } @{$self->get_tracks};
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
