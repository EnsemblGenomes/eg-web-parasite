=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::FTPtable;

### This module outputs a table of links to the FTP site

use strict;
use warnings;

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::Document::Table;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self = shift;

  my $hub             = new EnsEMBL::Web::Hub;
  my $species_defs    = $hub->species_defs;

  my $rel = $species_defs->SITE_RELEASE_VERSION;

  my @species = $species_defs->valid_species;
  my %title = (
    dna       => 'Masked and unmasked genome sequences associated with the assembly (contigs, chromosomes etc.)',
    cdna      => 'cDNA sequences for protein-coding genes',
    prot      => 'Protein sequences for protein-coding genes',
    rna       => 'Non-coding RNA gene predictions',
    embl      => 'Ensembl Genomes database dumps in EMBL nucleotide sequence database format',
    genbank   => 'Ensembl Genomes database dumps in GenBank nucleotide sequence database format',
    gtf       => 'Gene sets for each species in GTF format. These files include annotations of both coding and non-coding genes',
    gff3      => 'Gene sets for each species in GFF3 format. These files include annotations of both coding and non-coding genes',
    emf       => 'Alignments of resequencing data from the Compara database',
    gvf       => 'Variation data in GVF format',
    vcf       => 'Variation data in VCF format',
    vep       => 'Cache files for use with the VEP script',
    coll      => 'Additional regulation data (not in database)',
    bed       => 'Constrained elements calculated using GERP',
    files     => 'Additional release data stored as flat files rather than MySQL for performance reasons',
    ancestral => 'Ancestral Allele data in FASTA format',
    bam       => 'Alignments against the genome',
    core      => '%s core data export',
    otherfeatures     => '%s other features data export',
    variation      => '%s variation data export',
    funcgen   => '%s funcgen data export',
    pan       => 'Pan-taxomic Compara data export',
    compara   => '%s Compara data export',
    mart      => '%s BioMart data export',
    tsv       => 'Tab separated files containing selected data for individual species and from comparative genomics',

  );
  $title{$_} = encode_entities($title{$_}) for keys %title;

  my @rows;
  foreach my $spp (sort @species) {
    (my $sp_name = $spp) =~ s/_/ /;
     my $sp_dir =lc($spp);
     my $sp_var = lc($spp).'_variation';
     my $common = $species_defs->get_config($spp, 'SPECIES_COMMON_NAME');
     my $scientific = $species_defs->get_config($spp, 'SPECIES_SCIENTIFIC_NAME');

    my $genomic_unit = $species_defs->get_config($spp, 'GENOMIC_UNIT');
    my $collection;
    my $ftp_base_path_stub = "ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/releases/WBPS$rel";
       
    my $bioproject = uc((split('_', $spp))[2]);
    my $species_lower = lc(join('_',(split('_', $spp))[0..1]));

    my $data = {
		species            => qq{<em>$scientific</em>},
		bioproject         => qq{$bioproject},
		genomic            => qq{<a rel="external"  title="$title{'genomic'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic.fa.gz">FASTA</a>},
		genomic_masked     => qq{<a rel="external"  title="$title{'genomic_masked'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic_masked.fa.gz">FASTA</a>},
		genomic_softmasked => qq{<a rel="external"  title="$title{'genomic_softmasked'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic_softmasked.fa.gz">FASTA</a>},
		annotations        => qq{<a rel="external"  title="$title{'annotations'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.annotations.gff3.gz">GFF3</a>},
		proteins           => qq{<a rel="external"  title="$title{'proteins'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.protein.fa.gz">FASTA</a>},
		mRNA_transcripts   => qq{<a rel="external"  title="$title{'mRNA_transcripts'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.mRNA_transcripts.fa.gz">FASTA</a>},
		CDS_transcripts    => qq{<a rel="external"  title="$title{'CDS_transcripts'}" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.CDS_transcripts.fa.gz">FASTA</a>},
    };
    push(@rows, $data);
  }

  my $genomic_unit = $species_defs->GENOMIC_UNIT;

  my $table    = EnsEMBL::Web::Document::Table->new(
    [
      {key=>'species',    sort=>'html', title=>'Species'},
      {key=>'bioproject', sort=>'html', title=>'BioProject'},
      {key => 'genomic',      sort=>'none', title => 'Genomic'},    
      {key => 'genomic_masked',     sort=>'none', title => 'Masked Genomic'},   
      {key => 'genomic_softmasked',     sort=>'none', title => 'Soft-masked Genomic'},   
      {key => 'annotations',     sort=>'none', title => 'Annotations'},    
      {key => 'proteins',      sort=>'none', title => 'Proteins'},    
      {key => 'mRNA_transcripts',     sort=>'none', title => 'Full-length Transcripts'},   
      {key => 'CDS_transcripts',     sort=>'none', title => 'CDS Transcripts'},   
    ],
    \@rows,
    { data_table=>1, exportable=>0 }
  );
  $table->code = 'FTPtable::'.scalar(@rows);
  $table->{'options'}{'data_table_config'} = {iDisplayLength => 25};

  return sprintf(qq{<div id="species_ftp_dl" class="js_panel"><input type="hidden" class="panel_type" value="Content"/>%s</div>},
    $table->render);
      
}



1;
