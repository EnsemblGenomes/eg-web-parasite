=head1 LICENSE

Copyright [2009-2015] EMBL-European Bioinformatics Institute

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
    parasite_rnaseq     => 'RNA-Seq Alignments',
    ERP001209           => ['ERP001209', 'parasite_rnaseq'],
    ERP001238           => ['ERP001238', 'parasite_rnaseq'],
    ERP004459           => ['ERP004459', 'parasite_rnaseq'],
    ERP001556           => ['ERP001556', 'parasite_rnaseq'],
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

sub _add_datahub {
  my ($self, $menu_name, $url, $is_poor_name, $existing_menu) = @_;

  return ($menu_name, {}) if $self->{'_attached_datahubs'}{$url};

  my $trackhub  = EnsEMBL::Web::File::Utils::TrackHub->new('hub' => $self->hub, 'url' => $url);
  my $hub_info = $trackhub->get_hub({'assembly_lookup' => $self->species_defs->assembly_lookup, 
                                      'parse_tracks' => 1}); ## Do we have data for this species?
  
  if ($hub_info->{'error'}) {
    ## Probably couldn't contact the hub
    push @{$hub_info->{'error'}||[]}, '<br /><br />Please check the source URL in a web browser.';
  } else {
    my $shortLabel = $hub_info->{'details'}{'shortLabel'};
    $menu_name = $shortLabel if $shortLabel and $is_poor_name;

    my $menu     = $existing_menu || $self->tree->append_child($self->create_submenu($menu_name, $menu_name, { external => 1, datahub_menu => 1 }));

    my $node;
    my $assemblies =
      $self->hub->species_defs->get_config($self->species,'TRACKHUB_ASSEMBLY_ALIASES');
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
      $self->_add_datahub_node($node, $menu, $menu_name);

      $self->{'_attached_datahubs'}{$url} = 1;
    } else {
      my $assembly = $self->hub->species_defs->get_config($self->species, 'ASSEMBLY_VERSION');
      $hub_info->{'error'} = ["No sources could be found for assembly $assembly. Please check the hub's genomes.txt file for supported assemblies."];
    }
  }
  return ($menu_name, $hub_info);
}

1;

