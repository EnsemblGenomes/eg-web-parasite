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

package EnsEMBL::Web::Component::Search::Results;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use Data::Dumper;
use HTML::Entities;
use JSON;
use Lingua::EN::Inflect qw(PL);
use POSIX;
use EnsEMBL::Web::Object::get_compara_Member
use SiteDefs;
use EnsEMBL::Web::Document::TwoCol;
use Bio::EnsEMBL::Registry;

sub content {
  my $self   = shift;
  
  my $search = $self->object->Obj;
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  
  if (!$search->query_term) {
    return "<p>Enter the string you wish to search for in the box at the top.</p>";  
  }
      
  if (!$search->hit_count and !$search->filter_species) {
    return $self->no_hits_message;
  } 

  my $html;
  $html .= $self->_render_results_message;
 
  if ($search->filter_species) {
    $html .= sprintf('
      <div class="search_filter">
        <span>
          Filtered by species: <strong>%s</strong> <a href="?%s%s"><img src="/i/16/cross.png" title="Remove filter"></a>
        </span>
      </div>',
## ParaSite
      sprintf('%s (%s%s)', $self->hub->species_defs->get_config($search->filter_species, 'SPECIES_BIO_NAME'), $self->hub->species_defs->get_config($search->filter_species, 'SPECIES_BIOPROJECT'), $self->hub->species_defs->get_config($search->filter_species, 'SPECIES_STRAIN') ? " - " . $self->hub->species_defs->get_config($search->filter_species, 'SPECIES_STRAIN') : ''),
      $search->query_string
##
    ); 
  } elsif ($search->hit_count > 1 and $search->current_unit ne 'ensembl' and $search->current_unit ne 'wormbase' and $search->current_index eq 'gene' and $search->species eq 'all') {
   
    my @species = @{ $search->get_facet_species };
    $html .= $self->_render_filter_dropdown(\@species);
  }

  if ($search->hit_count) {
    $html .= $self->render_hit($_) for (@{$search->get_hits});
  }

  $html = qq{<div class="searchresults">\n$html\n</div>\n};  

  $html .= $self->render_pagination;

  return $html;
}

sub no_hits_message {
  my $self = shift;
  my $search       = $self->object->Obj;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $site_type    = $species_defs->ENSEMBL_SITETYPE;
  
  my $query        = $search->query_term;
  my $site         = $search->site;
    
  my @alt_links;
    
  if ($site =~ /ensemblthis/) {
    push @alt_links, qq{<li><a href="/Multi/psychic?q=$query;site=ensemblunit">search all species in $site_type</a></li>};
  }
  
  #if ($site =~ /ensemblthis|ensemblunit/) {
  #  push @alt_links, qq{<li><a href="/Multi/psychic?q=$query;site=ensembl_all">search all species in Ensembl Genomes</a></li>};
  #}
    
  my $alt_searches;
  $alt_searches = '<li>Broaden your search:<ul>' . join('', @alt_links) . '</ul></li>' if @alt_links;
 
  my $wildcards;
  if ($query !~ /\*$/) {
    (my $qs = $search->query_string) =~ s/q=[^;]+;/q=$query*;/;
    $wildcards = qq{<li>Try using wildcards, e.g. <a href="?$qs">'$query*'</a></li>};
  }

  my $species = $self->_render_species_message;
  $species = "<li>$species</li>" if $species;
  
  return qq{
    <p>Your search for <strong>'$query'</strong> returned no results</p>
    <p>
      Suggestions:
      <ul>
        $species
        <li>Make sure all terms are spelled correctly</li>
        $wildcards 
        $alt_searches
      </ul>
    </p>
    <br />
  }
}

# ParaSite: check for species name matches
sub _render_species_message {
  my $self = shift;
  my $search = $self->object->Obj;
  my $pager = $search->pager;
  my $hub = $self->hub;
  my (@matches, $string);

  my ($sp_term, $sp_genus) = $search->query_term =~ /^([A-Za-z])[\.]? ([A-Za-z]+)/ ? ($2, $1) : ($search->query_term, undef); # Deal with abbreviation of the genus
  $sp_term =~ s/genome$//; # Some users put the word genome at the end of their search string - remove this so we still get a match

  foreach($hub->species_defs->valid_species) {
    (my $species = $_) =~ s/\_/ /g;
    last if $sp_term =~ /\*/;
    next if $sp_genus && ($species !~ /^$sp_genus/i || $species !~ /^(.*?) .*$sp_term.*/i);
    push(@matches, $_) if $species =~ /$sp_term/i;
  }
  if(scalar(@matches) > 0) {
    my @links;
    foreach(@matches) {
      my $scientific = $hub->species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME');
      my $bioproject = $hub->species_defs->get_config($_, 'SPECIES_BIOPROJECT');
      my $strain = $hub->species_defs->get_config($_, 'SPECIES_STRAIN') ? sprintf("; %s", $hub->species_defs->get_config($_, 'SPECIES_STRAIN')) : '';
      my $display = sprintf("%s (%s%s)", $scientific, $bioproject, $strain);
      push(@links, qq{<a href="/$_/">$display</a>});
    }
    $string = "<p>Are you looking for " . join(", ", @links) . "?</p>";
    $string =~ s/(.*),/$1 or/;
  }

  return $string; 

}

sub _render_results_message {
  my $self = shift;
  my $search = $self->object->Obj; 
  my $pager = $search->pager;
  my $range = $search->hit_count <= $pager->entries_per_page ? $search->hit_count : sprintf "%s-%s of %s", $pager->first, $pager->last, $search->hit_count;
  my $site = $search->species eq 'all' ? $search->current_sitename . ($search->filter_species ? ' (filtered)' : '') : $search->species;
  my $index = $search->current_index =~ s/_/ /r;
  my $items = ucfirst(PL($index, $search->hit_count));
  my $html = '';

  $html .= $self->_render_species_message unless $index =~ /species/;

  if ($search->hit_count > 0) {
    $html .= "<h3>Showing $range $items found in $site</h3>";
    $html .= '<p>Results beyond 10000 not shown.</p>' if $pager->last >= 10000;
  } else {
    $html .= "<h3>No $items found in $site</h3>";
  }
  
  return $html;
}

sub _render_filter_dropdown {
  my ($self, $species) = @_;

  my $options;
  foreach (sort @$species) {
## ParaSite: get the correct display name
    my $display_name = sprintf('%s (%s%s)', $self->hub->species_defs->get_config($_, 'SPECIES_BIO_NAME'), $self->hub->species_defs->get_config($_, 'SPECIES_BIOPROJECT'), $self->hub->species_defs->get_config($_, 'SPECIES_STRAIN') ? " - " . $self->hub->species_defs->get_config($_, 'SPECIES_STRAIN') : '');
##
    $options .= qq{<option value="$_">$display_name</option>\n};
  }

  if(@$species) { 
    return qq{
      <div id="species_filter" class="js_panel">
        <input type="hidden" class="panel_type" name="speciesfilter" value="SpeciesFilterDropdown" />
        <div class="search_filter">
          <span>
            Filter by species: 
            <select>
              <option value="">Select a species...</option>
              $options
            </select>
          </span>
        </div>
      </div>
    };
  } else {
    return '<div id="species_filter" class="js_panel"><div class="search_filter"></div></div>';
  }
}

sub render_hit {
  my ($self, $hit) = @_;
  
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;

  my $species_name = ucfirst $hit->{system_name};
  my $species = sprintf('%s (%s%s)', $hub->species_defs->get_config($species_name, 'SPECIES_BIO_NAME'), $hub->species_defs->get_config($species_name, 'SPECIES_BIOPROJECT'), $hub->species_defs->get_config($species_name, 'SPECIES_STRAIN') ? " - " . $hub->species_defs->get_config($species_name, 'SPECIES_STRAIN') : '');
  $species = $hub->species_defs->SPECIES_DISPLAY_NAME->{lc($species_name)} unless $hub->species_defs->get_config($species_name, 'SPECIES_BIO_NAME');

  my $name = $hit->{name};
  
  my $table = EnsEMBL::Web::Document::TwoCol->new;

  if ($hit->{featuretype} eq 'Species') {

    $table->add_row("Taxonomy ID", $self->highlight($hit->{taxonomy_id}));
    $table->add_row("Assembly", $self->highlight($hit->{assembly_name}));
    $name = "<strong>$name</strong>";

  } elsif ($hit->{featuretype} eq 'Sequence region') {
    
    $table->add_row("Coordinate system", $hit->{coord_system});
    $table->add_row("Species", sprintf '<em><a href="%s">%s</a></em>', $hit->{species_path}, $self->highlight($species));
    $table->add_row("Location", qq(<a href="$hit->{species_path}/Location/View?r=$hit->{location};g=$hit->{id};db=$hit->{database}">$hit->{location}</a>));    
    $name = "<strong>$name</strong>";
  
  } else {
    my $parsed_description = $self->parse_description($hit->{description}, $hit->{species_path});
    $table->add_row("Description", ($parsed_description || 'n/a'));
    $table->add_row("Gene ID", sprintf('<a href="%s">%s</a>', $hit->{url}, $self->highlight($hit->{url} =~ m/Idhistory/ ? $hit->{id}.' (ID History)' : $hit->{id})));
    $table->add_row("Species", sprintf '<em><a href="%s">%s</a></em>', $hit->{species_path}, $self->highlight($species));
    
    if ($hit->{location}) {
## ParaSite: add WormBase JBrowse link, if available
      my $spp = $hit->{system_name};
      (my $jbrowse_region = $self->zoom_location($hit->{location})) =~ s/-/../;
      my $wb_location_url = defined($hub->species_defs->ENSEMBL_EXTERNAL_URLS->{uc("$spp\_jbrowse")}) ? $hub->get_ExtURL_link('WormBase', uc "$spp\_jbrowse", {'SPECIES'=>$spp, 'REGION'=>$jbrowse_region, 'HIGHLIGHT'=>''}) : '';
      my $jbrowse_link = $hub->get_ExtURL('PARASITE_JBROWSE', {'SPECIES'=>lc($spp), 'REGION'=>$jbrowse_region, 'HIGHLIGHT'=>''});
      $table->add_row("Location", sprintf '%s<br /><span class="wb-compara-out">[View region in <a href="%s">JBrowse</a> | <a href="%s/Location/View?r=%s;g=%s;db=">Ensembl</a>%s]</span>', $hit->{location}, $jbrowse_link, $hit->{species_path}, $self->zoom_location($hit->{location}), $hit->{id}, $wb_location_url ? " | $wb_location_url" : '');
## ParaSite
    } 
    
    if ($hit->{gene_synonym} && @{$hit->{gene_synonym}}) {
      my %unique;
      foreach my $synonym (@{$hit->{gene_synonym}}) {
        (my $key = lc $synonym) =~ s/[^a-z0-9]/_/ig;
        (my $value = ucfirst $synonym) =~ s/-/ /g;
        $unique{$key} = $value;
      }
      $table->add_row("Synonyms", $self->highlight(join(', <br />', sort values %unique)));
    }

    if ($hit->{genetree} && @{$hit->{genetree}}) {
## ParaSite: gene tree results have been modified
      if(scalar(@{$hit->{genetree}}) > 1) {
        my @links;
        foreach my $id (@{$hit->{genetree}}) {
          my $url = sprintf('%s/Gene/Compara_Tree?g=%s', $hit->{species_path}, $hit->{id});
          push(@links, sprintf('<a href="%s">%s</a>', $url, $self->highlight($id)));
        }
        $table->add_row("Gene trees", sprintf('View gene tree: %s', join(', ', @links)));
      } else {
        my $linktext;
        foreach my $id (@{$hit->{genetree}}) {
          my $url = sprintf('%s/Gene/Compara_Tree?g=%s', $hit->{species_path}, $hit->{id});
          $linktext = sprintf('<a href="%s">%s</a>', $url, "View gene tree");
        }
        $table->add_row("Gene tree", $linktext);
      }
## ParaSite
    }

    if ($hit->{WORMBASE_ORTHOLOG} && @{$hit->{WORMBASE_ORTHOLOG}}) {
      my $text = $self->process_orthologs($hit->{WORMBASE_ORTHOLOG}, 'WORMBASE_GENE');
      my $suffix = scalar(split(",", $text)) > 1 ? 's' : '';
      $table->add_row("<em>C. elegans</em> orthologue$suffix", $text);
    }

    #if ($hit->{ENSEMBL_ORTHOLOG} && @{$hit->{ENSEMBL_ORTHOLOG}}) {
    #  my $text = $self->process_orthologs($hit->{ENSEMBL_ORTHOLOG}, 'ENS_HS_GENE');
    #  my $suffix = scalar(split(",", $text)) > 1 ? 's' : '';
    #  $table->add_row("Human orthologue$suffix", $text);
    #}
    
    # format the name
    $name =~ s/\[/\[ /;
    $name =~ s/\]$/ \]/;
    $name =~ s/^([^\s]+)(.*)$/<strong>$1<\/strong><span class="small">$2<\/span>/;
  }
  
  my $info = $table->render;
   
  return qq(
    <div class="hit">
      <div class="title">
        <a class="name" href="$hit->{url}">$name</a>
      </div>
      $info
    </div>
  );
}

sub parse_description {
  my ($self, $description, $species_path) = @_;
  if ($description =~ m/current identifiers? \((.*)\)/) {
    my @cids = split /; /, $1;
    my $cids_href = join ("; ", map {sprintf '<a href="%s/Gene/Summary?g=%s">%s</a>', $species_path, $_, $self->highlight($_) } @cids);
    $description =~ s/$1/$cids_href/g;
  }
  return $description;
}

sub process_orthologs {
  my ($self, $orthologs, $source) = @_;
  my $cdb = 'compara';
  my $formatted;

  if($self->hub->database('compara')) {
    my $database = $self->hub->database($cdb);
    foreach(@{$orthologs}) {
      my $args = {'stable_id' => $_, 'cdb' => $compara_db};
      my $member = $self->get_compara_Member($args);
      #my $member = $database->get_GeneMemberAdaptor->fetch_by_stable_id($_);
      my $label = $member->display_label || $_;
      $label = "<strong>$label</strong>" if ($_ eq $self->object->Obj->query_term || $label eq $self->object->Obj->query_term);
      $_ = $self->hub->get_ExtURL_link($label, $source, $_);
    }
  } else {

    foreach(@{$orthologs}) {
      my $label = $_;
      $label = "<strong>$label</strong>" if ($_ eq $self->object->Obj->query_term || $label eq $self->object->Obj->query_term);
      $_ = $self->hub->get_ExtURL_link($label, $source, $_);
    }
 # }
  $formatted = join(', ', @{$orthologs});
  return $formatted;
}

sub highlight {
  my ($self, $string) = @_;
  my $search = $self->object->Obj;
  my $q = $search->query_term;
  $q =~ s/('|"|\(|\)|\|\+|-|\*)//g; # remove lucene operator chars
  my @terms = grep {$_ and $_ !~ /^AND|OR|NOT$/i} split /\s/, $q; # ignore lucene operator words
  $string =~ s/(\Q$_\E)/<em><strong>$1<\/strong><\/em>/ig foreach @terms;
  return $string;
}

# zoom out by 20% of gene length 
# or by 1000 for genes that cross circular orign and we can't calculate the length
sub zoom_location {
  my ($self, $location) = @_;
  my ($region, $start, $end) = $location =~ /(.*):(.*)-(.*)/;
  my $flank = 1000;  

  if ($start < $end) {
    my $length = $end - $start + 1;
    $flank = int( $length * 0.2 ); 
  }
  
  return  sprintf '%s:%s-%s',  $region, ( $start - $flank < 1 ? 1 : $start - $flank ), $end + $flank;
}

sub render_pagination {
  my $self   = shift;
  my $search = $self->object->Obj;
  
  return if !$search->query_term or $search->hit_count <= 10;
  
  my $pager = $search->pager;
  
  my $qs_params = $search->filter_species ? {filter_species => $search->filter_species} : {};
  my $query_string = $search->query_string($qs_params);
  
  my $html;
  
  if ( $pager->previous_page) {
    $html .= sprintf( '<a class="prev" href="?page=%s;%s">< Prev</a> ', $pager->previous_page, $query_string  );
  }

  foreach my $i (1..$pager->last_page) {
    if( $i == $pager->current_page ) {
      $html .= sprintf( '<span class="current">%s</span> ', $i );
    } elsif( $i < 5 || ($pager->last_page - $i) < 4 || abs($i - $pager->current_page + 1) < 4 ) {
      $html .= sprintf( '<a href="?page=%s;%s">%s</a>', $i, $query_string, $i );
    } else {
      $html .= '..';
    }
  }

  $html =~ s/\.\.+/ ... /g;

  if ($pager->next_page) {
    $html .= sprintf( '<a class="next" href="?page=%s;%s">Next ></a> ', $pager->next_page, $query_string );
  }

  return qq{<h4><div class="paginate">$html</div></h4>};
}

1;

