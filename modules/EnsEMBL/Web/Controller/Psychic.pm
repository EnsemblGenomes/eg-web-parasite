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

# $Id: Psychic.pm,v 1.8 2013-12-05 16:00:23 nl2 Exp $

package EnsEMBL::Web::Controller::Psychic;

### Pyschic search

use strict;

use Apache2::RequestUtil;
use CGI;
use URI::Escape qw(uri_escape);
use List::Util qw(first);

sub feature_map {
    return {
      affyprobe    => 'OligoProbe',
      oliogprobe   => 'OligoProbe',
      affy         => 'OligoProbe',
      oligo        => 'OligoProbe',
      snp          => 'SNP',
      variaton     => 'SNP',
      disease      => 'Gene',
      peptide      => 'Gene',
      transcript   => 'Gene',
      gene         => 'Gene',
      translation  => 'Gene',
      cdna         => 'GenomicAlignment',
      mrna         => 'GenomicAlignment',
      protein      => 'GenomicAlignment',
      domain       => 'Domain',
      marker       => 'Marker',
      family       => 'Family',
  };
}

sub psychic {
  my $self          = shift;
  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my $site_type     = lc $species_defs->ENSEMBL_SITETYPE;
  my $script        = $species_defs->ENSEMBL_SEARCH;
  my %sp_hash       = %{$species_defs->ENSEMBL_SPECIES_ALIASES};
  my $dest_site     = $hub->param('site') || 'ensemblunit';
  my $index         = $hub->param('idx')  || undef;
  my $query         = $hub->param('q');
  my $sp_param      = $hub->param('species');
  my $species       = $sp_param || (($hub->species !~ /^(common|multi)$/i and $dest_site ne 'ensemblunit') ? $hub->species : undef);
  my ($url, $site);

  if ($species eq 'all' && $dest_site eq 'ensembl') {
    $dest_site = 'ensembl_all';
    $species   = $species_defs->ENSEMBL_PRIMARY_SPECIES;
  }

  $query =~ s/^\s+//g;
  $query =~ s/\s+$//g;
  $query =~ s/\s+/ /g;

  $species = undef if $dest_site =~ /_all/;

  return $hub->redirect("http://www.ebi.ac.uk/ebisearch/search.ebi?db=allebi&query=$query")                          if $dest_site eq 'ebi';
  return $hub->redirect("http://www.sanger.ac.uk/search?db=allsanger&t=$query")                                      if $dest_site eq 'sanger';
  return $hub->redirect("http://www.ensemblgenomes.org/search/eg/$query") if $dest_site eq 'ensembl_genomes';
  return $hub->redirect("http://www.wormbase.org/search/all/$query") if $dest_site eq 'wormbase';

  if ($dest_site =~ /vega/) {
    if ($site_type eq 'vega') {
      $url = "/Multi/Search/Results?species=all&idx=All&q=$query";
    } else {
      $url  = "/Multi/Search/Results?species=all&idx=All&q=$query";
      $site = 'http://vega.sanger.ac.uk';
    }
  } elsif ($site_type eq 'vega') {
    $url  = "/Multi/Search/Results?species=all&idx=All&q=$query";
    $site = 'http://www.ensembl.org'; 
  } else {
    $url = "/Multi/Search/Results?species=$species&idx=All&q=$query";
  }

## EG :   
  my $qparams;
  foreach my $p (qw( collection species q)) {
      $qparams->{$p}  = $hub->param($p);
  }
  if ($dest_site =~ 'ensemblunit')  {
      $qparams->{'genomic_unit'} = $species_defs->GENOMIC_UNIT;
  }
## EG

  my $flag = 0;
  my $index_t;

  #if there is a species at the beginning of the query term then make a note in case we trying to jump to another location
  my ($query_species, $query_without_species);
  foreach my $sp (sort keys %sp_hash) {
    if ( $query =~ /^$sp /) {
      ($query_without_species = $query) =~ s/$sp//;
      $query_without_species =~ s/^ //;
      $query_species = $sp;
    }
  }

  my $species_path = $species_defs->species_path($species) || "/$species";

  ## If we have a species and a location can we jump directly to that page ?
  if ($species || $query_species ) {
    my $real_chrs = $hub->species_defs->ENSEMBL_CHROMOSOMES;
    my $jump_query = $query;
    if ($query_species) {
      $jump_query = $query_without_species;
      $species_path = $species_defs->species_path($query_species);
    }

    my @query_array = split (/:/, $jump_query);
    my $chr_name;

    if ($jump_query =~ s/^(chromosome)//i || $jump_query =~ s/^(chr)//i) {
      $jump_query =~ s/^ //;
      
      # match chromosomes names like 'chr1', 'Chromosome', 'chromosome'
      if ( $chr_name = first { $jump_query eq $_ || uc($_) eq uc($query_array[0]) } @$real_chrs) {
        $flag = $1;
        $index_t = 'Chromosome';
      }
    }
    elsif ($jump_query =~ /^(contig|clone|ultracontig|supercontig|scaffold|region)/i) {
      $jump_query =~ s/^(contig|clone|ultracontig|supercontig|scaffold|region)\s+//i;
      $index_t = 'Sequence';
      $flag = $1;
    }

    ## match any of the following:
    if ($jump_query =~ /^\s*([-\.\w]+)[: ]([\d\.]+?[MKG]?)( |-|\.\.|,)([\d\.]+?[MKG]?)$/i || $jump_query =~ /^\s*([-\.\w]+)[: ]([\d,]+[MKG]?)( |\.\.|-)([\d,]+[MKG]?)$/i) {
      my ($seq_region_name, $start, $end) = ($1, $2, $4);

      $seq_region_name =~ s/chr//;
      $seq_region_name =~ s/ //g;
      $start = $self->evaluate_bp($start);
      $end   = $self->evaluate_bp($end);
      ($end, $start) = ($start, $end) if $end < $start;

      my $script = 'Location/View';
      $script    = 'Location/Overview' if $end - $start > 1000000;

      if ($index_t eq 'Chromosome') {
        $url  = "$species_path/Location/Chromosome?r=$seq_region_name";
        $flag = 1;
      } else {
        $url  = $self->escaped_url("$species_path/$script?r=%s", $seq_region_name . ($start && $end ? ":$start-$end" : ''));
        $flag = 1;
      }
    }
    else {
      if ($index_t eq 'Chromosome') {
        $jump_query =~ s/ //g;
        $url  = "$species_path/Location/View?r=".$chr_name.$jump_query;
        $flag = 1;
      } elsif ($index_t eq 'Sequence') {
        $jump_query =~ s/ //g;
        $url  = "$species_path/Location/View?region=$jump_query";
        $flag = 1;
      }
    }

    ## other pairs of identifiers
    if ($jump_query =~ /\.\./ && !$flag) {
      ## str.string..str.string
      ## str.string-str.string
      $jump_query =~ /([\w|\.]*\w)(\.\.)(\w[\w|\.]*)/;
      $url   = $self->escaped_url("$species_path/jump_to_contig?type1=all;type2=all;anchor1=%s;anchor2=%s", $1, $3);
      $flag  = 1;
    }
  }
  
## EG @ strip feature map keywords and set index
  if ($query =~ /^(\w+)\b/) {
    if ($index_t = $self->feature_map->{lc $1}) {
      $query   =~ s/^\w+\W*//;
      $index = $index_t;
    }
  }
## EG

## EG
  # quote terms that contain colons so they are not mis-interpreted by Lucene 
  # e.g. PO:0000013 -> "PO:0000013"
  if ($query =~ /:/ and $query !~ /"/) { # ignore if already contains quotes
    my @terms = split /\s+/, $query;
    my @quoted = map {$_ =~ /:/ ? qq{"$_"} : $_} @terms; 
    $query = join(' ', @quoted);
  }
## EG
  
  if (!$flag) {
##EBEYE
      $species = 'all' if (lc($species) eq 'multi' or $site_type eq 'ensemblunit');
      if ($species and lc($species) ne 'all') {
        $species = $species_defs->species_label($species, 1);
      }
##EBEYE

    $url = 
      $query =~ /^BLA_\w+$/               ? $self->escaped_url('/Multi/blastview/%s', $query) :                                                                 ## Blast ticket
      $query =~ /^\s*([ACGT]{20,})\s*$/i  ? $self->escaped_url('/Multi/blastview?species=%s;_query_sequence=%s;query=dna;database=dna', $species, $1) :         ## BLAST seq search
      $query =~ /^\s*([A-Z]{20,})\s*$/i   ? $self->escaped_url('/Multi/blastview?species=%s;_query_sequence=%s;query=peptide;database=peptide', $species, $1) : ## BLAST seq search
      $self->escaped_url(($species eq 'ALL' || !$species ? '/Multi' : $species_path) . "/$script?species=%s;idx=%s;q=%s", $species || 'all', $index, $query);    # everything else!
  }

## EG @ add EG params

## EBEYE
#  if (my $gu = $qparams->{genomic_unit}) {
#      $url .= ";genomic_unit=$gu";
#  }
  if (my $cl = $qparams->{collection}) {
      $url .= ";collection=$cl";
  }
  if ($dest_site) {
    $url .= ";site=$dest_site";
  }
#  if ( $dest_site eq 'ensembl_all') {
#      $url .= ";toplevel=genomes";
#  }
## EBEYE

## EG 

  $hub->redirect($site . $url);
}

1;
