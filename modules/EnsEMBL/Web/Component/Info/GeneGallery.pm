=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Info::GeneGallery;

## 

use strict;

use base qw(EnsEMBL::Web::Component::Info::Gallery);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $hub  = $self->hub;
  my $variation_db = $hub->species_defs->databases->{'DATABASE_VARIATION'};

  my $layout = [
                {
                    'title' => 'Sequence &amp; Structure',
                    'pages' => ['JBrowse Genome Browser', 'Ensembl Genome Browser', 'Immediate Neighbourhood', 'Summary Information', 'Splice Variants', 'Gene Sequence', 'External References'],
                    'icon'  => 'dna.png',
                  },
                {
                  'title' => 'Function & Expression',
                  'pages' => ['Table of Ontology Terms', 'Gene Expression'],
                  'icon'  => 'regulation.png',
                },
                  {
                    'title' => 'Transcripts & Proteins',
                    'pages' => ['Transcript Table', 'Transcript Summary', 'Transcript Comparison', 'Transcript Image', 'Exon Sequence', 'Protein Summary', 'Transcript cDNA', 'Protein Sequence', 'Domains and Features', 'Transcript Identifiers'],
                    'icon'  => 'protein.png',
                  },
                {
                    'title' => 'Comparative Genomics',
                    'pages' => ['Gene Tree', 'Summary of Orthologues', 'Table of Orthologues', 'Summary of Paralogues', 'Table of Paralogues', 'Alignment Image'],
                    'icon'  => 'compara.png',
                },
                ];

  return $self->format_gallery('Gene', $layout, $self->_get_pages);
}

sub _get_pages {
  ## Define these in a separate method to make content method cleaner
  my $self = shift;
  my $hub = $self->hub;
  my $g = $hub->param('g');

  my $builder   = EnsEMBL::Web::Builder->new($hub);
  my $factory   = $builder->create_factory('Gene');
  my $object    = $factory->object;

  if (!$object) {
    return $self->warning_panel('Invalid identifier', 'Sorry, that identifier could not be found. Please try again.');
  }
  else {

    my $r = $hub->param('r');
    unless ($r) {
      $r = sprintf '%s:%s-%s', $object->slice->seq_region_name, $object->start, $object->end;
    }

    my $avail = $hub->get_query('Availability::Gene')->go($object,{
                          species => $hub->species,
                          type    => $object->get_db,
                          gene    => $object->Obj,
                        })->[0];
    my $not_strain      = $hub->species_defs->IS_STRAIN_OF ? 0 : 1;
    my $has_gxa         = $object->gxa_check;
    my $has_rna         = ($avail->{'has_2ndary'} && $avail->{'can_r2r'}); 
    my $has_tree        = ($avail->{'has_species_tree'} && $not_strain);
    my $has_orthologs   = ($avail->{'has_orthologs'} && $not_strain);
    my $has_paralogs    = ($avail->{'has_paralogs'} && $not_strain);
    my $has_regulation  = !!$hub->species_defs->databases->{'DATABASE_FUNCGEN'};
    my $variation_db    = $hub->species_defs->databases->{'DATABASE_VARIATION'};
    my $has_populations = $variation_db->{'#STRAINS'} if $variation_db ? 1 : 0;
    my $opt_variants    = $variation_db ? ', with optional variant annotation' : '';

    my ($sole_trans, $multi_trans, $multi_prot, $proteins);
    my $transcripts = $object->Obj->get_all_Transcripts || [];

    if (scalar @$transcripts > 1) {
      $multi_trans = {
                      'type'    => 'Transcript',
                      'param'   => 't',
                      'values'  => [{'value' => '', 'caption' => '-- Select transcript --'}],
                      };
    }

    foreach my $t (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @$transcripts) {
      if ($avail->{'multiple_transcripts'}) {
        my $name = sprintf '%s (%s)', $t->external_name || $t->{'stable_id'}, $t->biotype;
        push @{$multi_trans->{'values'}}, {'value' => $t->stable_id, 'caption' => $name};
      }
      else {
        $sole_trans = $t->stable_id;
      }
      $proteins->{$t->stable_id} = $t->translation if $t->translation;
    }
    
    my $prot_count = scalar keys %$proteins;
    if ($prot_count > 1) {
      $multi_prot = {
                      'type'    => 'Protein',
                      'param'   => 'p',
                      'values'  => [{'value' => '', 'caption' => '-- Select protein --'}],
                      };
      foreach my $id (sort {$proteins->{$b}->length <=> $proteins->{$a}->length} keys %$proteins) { 
        my $p     = $proteins->{$id};
        my $text  = sprintf '%s (%s aa)', $p->stable_id, $p->length;
        push @{$multi_prot->{'values'}}, {'value' => $id, 'caption' => $text};
      }
    }

    return {
            'JBrowse Genome Browser' => {
                                  'url'       => sprintf('/jbrowse/browser/%s?loc=%s', lc($hub->species), $r),
                                  'img'       => 'location_jbrowse',
                                   'caption'  => 'View the position of this gene in a interactive genome browser',
                                },
            'Ensembl Genome Browser' => {
                                  'link_to'   => {'type'    => 'Location',
                                                  'action'  => 'View',
                                                  'r'      => $r,
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'location_genoverse',
                                  'caption'   => 'View the position of this gene in our scrollable genome browser',
                                },
            'Immediate Neighbourhood' => {
                                  'link_to'   => {'type'    => 'Gene',
                                                  'action'  => 'Summary',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_summary_image',
                                  'caption'   => 'View this gene in its genomic location',
                                },
            'Region Comparison' => {
                                  'link_to'   => {'type'      => 'Location',
                                                  'action'    => 'Multi',
                                                  'r'      => $r,
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'location_compare',
                                  'caption'   => ' View your gene compared to its orthologue in a species of your choice',
                                },
            'Summary Information' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Summary',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_summary',
                                  'caption'   => 'General information about this gene, e.g. identifiers and synonyms',
                                },
            'Splice Variants' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Splice',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_splice',
                                  'caption'   => 'View the alternate transcripts of this gene',
                                },
            'Gene Sequence' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Sequence',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_sequence',
                                  'caption'   => 'DNA sequence of this gene'.$opt_variants, 
                                },
            'Gene Tree' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Tree',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_tree',
                                  'caption'   => 'Tree showing homologues of this gene across multiple species',
                                  'disabled'  => !$has_tree,
                                },
            'Gene Tree Alignments' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Tree',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_tree_align',
                                  'caption'   => "Alignments of this gene's homologues across multiple species",
                                  'disabled'  => !$has_tree,
                                },
            'Summary of Orthologues' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Ortholog',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_ortho_summary',
                                  'caption'   => 'Table showing numbers of different types of orthologue (1-to-1, 1-to-many, etc) in various taxonomic groups',
                                  'disabled'  => !$has_orthologs,
                                  'message'   => 'It has no orthologues',
                                },
            'Table of Orthologues' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Ortholog',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_ortho_table',
                                  'caption'   => 'Table of orthologues in other species, with links to gene tree, alignments, etc.',
                                  'disabled'  => !$has_orthologs,
                                  'message'   => 'It has no orthologues',
                                },
            'Table of Paralogues' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Paralog',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_para_table',
                                  'caption'   => 'Table of within-species paralogues, with links to alignments of cDNAs and proteins',
                                  'disabled'  => !$has_paralogs,
                                  'message'   => 'It has no paralogues',
                                },
            'Table of Ontology Terms' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Ontologies',
                                                  'function'  => 'biological_process',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_ontology',
                                  'caption'   => 'Table of ontology terms linked to this gene',
                                },
            'Gene Expression' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'ExpressionAtlas',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_gxa',
                                  'caption'   => 'Interactive heatmap indicating tissue-specific expression patterns of this gene',
                                  'disabled'  => !$has_gxa,
                                },
            'Transcript Comparison' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'TranscriptComparison',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_transcomp',
                                  'caption'   => 'Compare the sequence of two or more transcripts of a gene'.$opt_variants,
                                  'disabled'  => !$multi_trans,
                                  'message'   => 'It has only one transcript',
                                },
            'External References' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Matches',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_xref',
                                  'caption'   => 'Links to supporting / corresponding records in external databases',
                                },
            'Transcript Summary' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Summary',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_summary',
                                  'caption'   => 'General information about a particular transcript of this gene',
                                  'multi'     => $multi_trans,
                                },
            'Transcript Table' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Summary',
                                                  'g'         => $g,
                                                 },
                                  'img'       => 'trans_table',
                                  'caption'   => "Table of information about all transcripts of this gene (click on the 'Show transcript table' button on any gene or transcript page)",
                                },
            'Exon Sequence' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Exons',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_exons',
                                  'caption'   => 'Sequences of individual exons within a transcript'.$opt_variants,
                                  'multi'     => $multi_trans,
                                },
            'Transcript cDNA' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Sequence_cDNA',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_cdna',
                                  'caption'   => 'cDNA sequence of an individual transcript'.$opt_variants,
                                  'multi'     => $multi_trans,
                                },
            'Protein Sequence' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Sequence_Protein',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_protein_seq',
                                  'caption'   => 'Protein sequence of an individual transcript'.$opt_variants,
                                  'disabled'  => !$prot_count,
                                  'multi'     => $multi_prot,
                                },
            'Protein Summary' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'ProteinSummary',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_protein',
                                  'caption'   => "Image representing the domains found within proteins encoded by the gene’s transcripts",
                                  'disabled'  => !$prot_count,
                                  'multi'     => $multi_prot,
                                },
            'Domains and Features' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Domains',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'prot_domains',
                                  'caption'   => 'Table of protein domains and other structural features',
                                  'multi'     => $multi_prot,
                                },
            'Transcript Identifiers' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Similarity',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_xref',
                                  'caption'   => 'Links to supporting / corresponding records in external databases',
                                  'multi'     => $multi_trans,
                                },

            };
  }

}

1;
