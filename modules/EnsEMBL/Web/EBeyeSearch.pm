=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::EBeyeSearch;

use strict;
use Data::Dumper;
use Data::Page;
use DBI;
use URI::Escape;
use EnsEMBL::Web::EBeyeSearch::REST;
use EnsEMBL::Web::EBeyeSearch::WormBaseREST;
use EnsEMBL::Web::DBSQL::MetaDataAdaptor;

my $results_cutoff = 10000;
my $default_pagesize = 10; 

my $debug = 0;

sub new {
  my($class, $hub) = @_;
    
  my $self = bless {
    hub  => $hub,
    rest => EnsEMBL::Web::EBeyeSearch::REST->new(base_url => $SiteDefs::EBEYE_REST_ENDPOINT),
    wormrest => EnsEMBL::Web::EBeyeSearch::WormBaseREST->new(),
  }, $class;
  
  return $self;
}

sub hub            { return $_[0]->{hub} };
sub ws             { return $_[0]->{ws} };
sub rest           { return $_[0]->{rest} };
sub wormrest       { return $_[0]->{wormrest} };
sub query_term     { return $_[0]->hub->param('q') };
sub species        { return $_[0]->hub->param('species') || 'all' };
sub filter_species { return $_[0]->hub->param('filter_species') };
sub collection     { return $_[0]->hub->param('collection') || 'all' };
sub site           { return $_[0]->hub->param('site') || 'ensemblthis' };
sub current_page   { return $_[0]->hub->param('page') || 1 };

sub current_index {
  my $self = shift;
  
  (my $index = $self->hub->function) =~ s/_[^_]+$//; # strip last part
  my $hit_counts = $self->get_hit_counts;
  $index = (sort keys %$hit_counts)[0] unless exists $hit_counts->{$index};
  
  return $index || 'gene';
}

sub current_unit {
  my $self = shift;
  
  my $unit = (split /_/, $self->hub->function)[1];
  my $index = $self->current_index;
  my $hit_counts = $self->get_hit_counts;
  $unit = (sort {$self->unit_sort($a, $b)} keys %{$hit_counts->{$index}->{by_unit}})[0] 
    unless exists $hit_counts->{$index}->{by_unit}->{$unit};
    
  return $unit || $SiteDefs::GENOMIC_UNIT;
}

sub current_sitename {
  my $self = shift;  
  return $SiteDefs::EBEYE_SITE_NAMES->{lc($self->current_unit)} || $self->current_unit;
}

sub ebeye_query {
  my ($self, $no_genomic_unit) = @_;
  
  my @parts;
  push @parts, $self->query_term;
  push @parts, 'species:' . $self->species if $self->species ne 'all';
  push @parts, 'collection:' . $self->collection if $self->collection ne 'all';
  
  return join ' AND ', @parts;
}

sub pager {
  my ($self, $page_size) = @_;

  my $pager = Data::Page->new();
  $pager->total_entries($self->hit_count > 10000 ? 10000 : $self->hit_count);
  $pager->entries_per_page($page_size || 10);
  $pager->current_page($self->current_page);
  
  return $pager; 
}

sub hit_count {
  my $self = shift;
  return $self->{_hit_count} if defined $self->{_hit_count};
  
  if ($self->filter_species) {
  
    # get dynamic hit count based on current species filter
    my $query = sprintf("%s AND genomic_unit:%s AND species:%s",
      $self->ebeye_query,
      $self->current_unit,
      $self->filter_species,
    );
    my $index = $self->current_index;
    return $self->{_hit_count} = $self->rest->get_results_count("wormbaseParasite", $query) || 0;
  
  } else {
  
    # get cached hit count
    my $hit_counts = $self->get_hit_counts; 
    return $self->{_hit_count} = $hit_counts->{$self->current_index}->{by_unit}->{$self->current_unit};
  
  }
}

sub get_hit_counts {
  my ($self) = @_;
  return $self->{_hit_counts} if $self->{_hit_counts};
  return {} unless $self->query_term;
  
  my $species_defs = $self->hub->species_defs;
  my $query = $self->ebeye_query;
  my $domains_by_unit;
  my $hit_counts;

  # ensembl genomes gene
  #my @units = $self->site =~ /^(ensemblthis|ensemblunit)$/ ? ($species_defs->GENOMIC_UNIT) : @{$SiteDefs::EBEYE_SEARCH_UNITS};
  my @units = @{$SiteDefs::EBEYE_SEARCH_UNITS};
  foreach my $unit (@units) {
    if($unit =~ /wormbase/) {
      my $count = $self->wormrest->get_results_count('wormbase', $query);
      $hit_counts->{gene}->{by_unit}->{'wormbase'} = $count;
    } else {
      my $count = $self->rest->get_results_count('wormbaseParasite', "$query AND genomic_unit:$unit");
      $hit_counts->{gene}->{by_unit}->{$unit} = $count;
    }
  }

  # ensembl gene
  if ($self->site eq 'ensembl_all') {
    my $count;
    eval { $count = $self->rest->get_results_count('ensembl_gene', $query) };
    warn $@ if $@;
    $hit_counts->{gene}->{by_unit}->{'ensembl'} = $count if $count > 0;
  }
  
#  # species  
#  if ($self->species eq 'all' and my $counts = $self->get_species_hit_counts) {
#    $hit_counts->{species}->{by_unit} = $counts;
#  }
  
#  # seq reguion
#  if (my $counts = $self->get_seq_region_hit_counts) {
#    $hit_counts->{'sequence_region'}->{by_unit} = $counts;
#  }
  
  # calculate totals
  my $grand_total = 0;
  foreach my $index (keys %$hit_counts) {
    my $total = 0;
    foreach my $unit (keys %{$hit_counts->{$index}->{by_unit}}) {
      $total += $hit_counts->{$index}->{by_unit}->{$unit};
    }
    $hit_counts->{$index}->{total} = $total;
    $grand_total += $total;
  }
  $self->{_hit_count_total} = $grand_total;
  
  if ($debug) {
    warn "\n--- EBEYE get_hit_counts ---\n";
    warn "Site type [" . $self->site . "]\n";
    warn "Units to search [" . join(', ', @units) . "]\n";
    warn "Query [$query]\n";
    warn Data::Dumper->Dump([$hit_counts], ['$hit_counts']) . "\n";
  }
  
  return $self->{_hit_counts} = $hit_counts;
}

sub get_hits {
  my $self = shift;
  my $dispatcher = {
#    genome          => sub { $self->get_species_hits },
#    sequence_region => sub { $self->get_seq_region_hits },
#    variant         => sub { $self->get_variant_hits },
    gene            => sub { $self->get_gene_hits },
  };
  my $hits = $dispatcher->{$self->current_index}->();
  
  $debug && Data::Dumper->Dump([$hits], ['$hits']) . "\n";

  return $hits;
}

sub get_facet_species {
  my $self         = shift;
  my $index        = $self->current_index;
  my $unit         = $self->current_unit;
  my $division     = 'Ensembl' . $unit eq 'ensembl' ? '' : ucfirst($unit);
  my $domain       = $unit eq 'ensembl' ? "ensembl_$index" : "wormbaseParasite";
  my $query        = $unit eq 'ensembl' ? $self->ebeye_query : $self->ebeye_query . " AND genomic_unit:$unit";
  my $facet_values = $self->rest->get_facet_values($domain, $query, 'TAXONOMY', {facetcount => 1000});
  my @taxon_ids    = map {$_->{value}} @$facet_values;
  my $meta         = EnsEMBL::Web::DBSQL::MetaDataAdaptor->new($self->hub);
  
  unless ($meta and $meta->genome_info_adaptor) {
    warn "Cannot get facet species: looks like the genome info database is unavailable";
    return [];
  }

  my $genomes;
  if (@taxon_ids < 1000 or $unit eq 'ensembl') {
    # get species names for given taxon ids
    $genomes = $meta->genome_info_adaptor->fetch_all_by_taxonomy_ids(\@taxon_ids);
  } else {
    # we hit the EBEye facet limit - so present all species instead
    $genomes = $meta->genome_info_adaptor->fetch_all_by_division($division);
  }
  
  return [ map {ucfirst $_->species} @$genomes ];  
}

sub get_gene_hits {
  my ($self) = @_;
  return {} unless $self->query_term;
  
  my $index          = $self->current_index;
  my $unit           = $self->current_unit;
  my $filter_species = $self->filter_species;
  my $domain         = $unit eq 'ensembl' ? "ensembl_$index" : "wormbaseParasite";
  my $pager          = $self->pager;
  my $hits;

  if($unit =~ /^wormbase$/) {
    my @single_fields  = qw(id label taxonomy);
    my @multi_fields   = qw();
    my $query          = $self->ebeye_query;
    $hits = $self->wormrest->get_results_as_hashes($domain, $query,
      {
        page   => $pager->current_page
      });
  } else {
    my @single_fields  = qw(id name description species featuretype location genomic_unit system_name database);
    my @multi_fields   = qw(transcript gene_synonym genetree WORMBASE_ORTHOLOG);
    my $query          = $self->ebeye_query;
       $query         .= " AND genomic_unit:$unit" if $unit ne 'ensembl';
       $query         .= " AND species:$filter_species" if $filter_species;
    $hits = $self->rest->get_results_as_hashes($domain, $query, 
      {
        fields => join(',', @single_fields, @multi_fields), 
        start  => $pager->first - 1, 
        size   => $pager->entries_per_page
      }, 
      { single_values => \@single_fields }
    );
  }

  foreach my $hit (@$hits) {
    
    my $transcript = ref $hit->{transcript} eq 'ARRAY' ? $hit->{transcript}->[0] : (split /\n/, $hit->{transcript})[0];
    my $url = "$hit->{species_path}/Gene/Summary?g=$hit->{id}";
    $url .= ";r=$hit->{location}" if $hit->{location};
    $url .= ";t=$transcript" if $transcript;
    $url .= ";db=$hit->{database}" if $hit->{database}; 
    $hit->{url} = $url;

    my $is_ensembl = ($hit->{domain_source} =~ /ensembl_gene/m);
    $hit->{species_path} = $self->species_path( $hit->{system_name}, $hit->{genomic_unit}, $is_ensembl );
  }

  return $hits;
}

# Hacky method to make a cross-site species path
sub species_path {
  my ($self, $species, $genomic_unit, $want_ensembl) = @_;
  my $species_defs = $self->hub->species_defs;
  my $path         = $species_defs->species_path(ucfirst($species));

  if ($path =~ /^\/$species/i and !$species_defs->valid_species(ucfirst $species) and $genomic_unit) {
    # there was no direct mapping in current unit, use the genomic_unit to add the subdomin
    $path = sprintf 'http://parasite.wormbase.org/%s', $species;
  } 
    
  # If species is in both Ensembl and EG, then $species_defs->species_path will 
  # return EG url by default - sometimes we know we want ensembl
  $path =~ s/http:\/\/[a-z]+\./http:\/\/www\./ if $want_ensembl;

  return $path;
}

sub unit_sort {
  my ($self, $a, $b) = @_;
  my $species_defs = $self->hub->species_defs;
  
  # order units with current site first and Ensembl last 
  my $site = $species_defs->GENOMIC_UNIT;
  return -1 if $a =~ /^$site$/i or $b =~ /^ensembl$/i;
  return  1 if $b =~ /^$site$/i or $a =~ /^ensembl$/i;
  return $a cmp $b;
}

sub query_string {
  my ($self, $extra_args) = @_;
  my $core = sprintf("q=%s;species=%s;collection=%s;site=%s", 
    uri_escape($self->query_term), 
    uri_escape($self->species), 
    uri_escape($self->collection),
    uri_escape($self->site),
  );
  my $extra;
  if (ref $extra_args eq 'HASH') {
    while (my ($key, $value) =  each %{$extra_args}) {
      $extra .= ";$key=$value";
    }
  }
  return $core . $extra;
}

1;
