=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

sub glyphset_configs {
  my $self = shift;

  if (!$self->{'ordered_tracks'}) {
    my @tracks      = $self->get_tracks;
    my $track_order = $self->track_order;

    my ($pointer, $first_track, $last_pointer, $i, %lookup, @default_order, @ordered_tracks);

    my (@forward_order, @reverse_order);

## ParaSite: using unshift on a single array causes the attached tracks to display in the reverse order for forward strand
    foreach my $track ($self->default_track_order(@tracks)) {
      my $strand = $track->get('strand');
      if ($strand =~ /^[rf]$/) {
        if ($strand eq 'f') {
          push @forward_order, $track;
        } else {
          push @reverse_order, $track;
        }
      } else {
        my $clone = $self->_clone_track($track);

        $clone->set('drawing_strand', 'f');
        $track->set('drawing_strand', 'r');

        unshift @forward_order, $clone;
        push    @reverse_order, $track;
      }
    }

    push(@forward_order, @reverse_order);
    @default_order = @forward_order;
## ParaSite

    if ($self->get_parameter('sortable_tracks')) {

      # make a 'double linked list' to make it easy to apply user sorting on it
      for (@default_order) {
        $_->set('sortable', 1) unless $self->{'unsortable_menus'}->{$_->parent_key};
        $lookup{ join('.', $_->id, $_->get('drawing_strand') || ()) } = $_;
        $_->{'__prev'} = $last_pointer if $last_pointer;
        $last_pointer->{'__next'} = $_ if $last_pointer;
        $last_pointer = $_;
      }

      # Apply user track sorting now
      $pointer = $first_track = $default_order[0];
      $pointer = $pointer->{'__next'} while $pointer && !$pointer->get('sortable'); # these tracks can't be moved from the beginning of the list
      $pointer = $pointer->{'__prev'} || $default_order[-1]; # point to the last track among all the immovable tracks at beginning of the track list
      for (@$track_order) {
        my $track = $lookup{$_->[0]} or next;
        my $prev  = $_->[1] && $lookup{$_->[1]} || $pointer; # pointer (and thus prev) could possibly be undef if there was no immovable track in the beginning
        my $next  = $prev ? $prev->{'__next'} : undef;

        # if $prev is undef, it means $track is supposed to moved to first position in the list, thus $next should be current first track
        # First track in the list could possibly have changed in the last iteration of this loop, so rewind it before setting $next
        if (!$prev) {
          $first_track  = $first_track->{'__prev'} while $first_track->{'__prev'};
          $next         = $first_track;
        }

        $track->{'__prev'}{'__next'}  = $track->{'__next'} if $track->{'__prev'};
        $track->{'__next'}{'__prev'}  = $track->{'__prev'} if $track->{'__next'};
        $track->{'__prev'}            = $prev;
        $track->{'__next'}            = $next;
        $track->{'__prev'}{'__next'}  = $track if $track->{'__prev'};
        $track->{'__next'}{'__prev'}  = $track if $track->{'__next'};
      }

      # Get the first track in the list after sorting and create a new ordered list starting from that track
      $pointer = $pointer->{'__prev'} while $pointer->{'__prev'};
      delete $pointer->{'__prev'};
      $pointer->set('order', ++$i);
      push @ordered_tracks, $pointer;

      while ($pointer = $pointer->{'__next'}) {
        delete $pointer->{'__prev'}{'__next'};
        delete $pointer->{'__prev'};
        $pointer->set('order', ++$i);
        push @ordered_tracks, $pointer;
      }

      delete $pointer->{'__next'};

      $self->{'ordered_tracks'} = \@ordered_tracks;

    } else {
      $self->{'ordered_tracks'} = \@default_order;
    }
  }

  return $self->{'ordered_tracks'};
}

1;

