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

  my @rows;
  foreach my $spp (sort @species) {
    (my $sp_name = $spp) =~ s/_/ /;
     my $sp_dir =lc($spp);
     my $sp_var = lc($spp).'_variation';
     my $common = $species_defs->get_config($spp, 'SPECIES_COMMON_NAME');
     my $scientific = $species_defs->get_config($spp, 'SPECIES_SCIENTIFIC_NAME');

    my $genomic_unit = $species_defs->get_config($spp, 'GENOMIC_UNIT');
    my $collection;
    my $ftp_base_path_stub = $species_defs->SITE_FTP . "/releases/WBPS$rel";
       
    my $bioproject = $species_defs->get_config($spp, 'SPECIES_BIOPROJECT');
    my $species_lower = lc(join('_',(split('_', $spp))[0..1]));

    my $data = {
      species            => qq{<em>$scientific</em>},
      bioproject         => qq{$bioproject},
      genomic            => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic.fa.gz">FASTA</a>},
      genomic_masked     => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic_masked.fa.gz">FASTA</a>},
      genomic_softmasked => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic_softmasked.fa.gz">FASTA</a>},
      annotations        => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.annotations.gff3.gz">GFF3</a> / <a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.canonical_geneset.gtf.gz">GTF</a>},
      proteins           => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.protein.fa.gz">FASTA</a>},
      mRNA_transcripts   => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.mRNA_transcripts.fa.gz">FASTA</a>},
      CDS_transcripts    => qq{<a rel="notexternal" href="$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.CDS_transcripts.fa.gz">FASTA</a>},
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
