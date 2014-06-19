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

use SiteDefs;
use EnsEMBL::Web::Document::TwoCol;
use Bio::EnsEMBL::Registry;

sub content {
  my $self   = shift;
  
  my $search = $self->object->Obj;
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  
  # GeneTrees:
  my $gtsearch     = $hub->param('gtsearch') || 0; 
  my $pager = $search->pager;  
  my $dba   = $hub->param('pancompara') ? $hub->database('compara_pan_ensembl') : $hub->database('compara');
  my $tree_counter = 0;
  my @params         = grep { $_ =~ /gtsearch/ || $_ =~ /pancompara/ } $hub->param;

  if (!$search->query_term) {
    return "<p>Enter the string you wish to search for in the box at the top.</p>";  
  }
      
  if (!$search->hit_count and !$search->filter_species) {
    return $self->no_hits_message;
  } 

  my $html;
  $html .= $self->_render_results_message unless $gtsearch;
 
  if ($SiteDefs::EBEYE_FILTER) {
    if ($search->filter_species) {
      $html .= sprintf('
        <div class="search_filter">
          <span>
            Filtered by species: <strong>%s</strong> <a href="?%s%s"><img src="/i/16/cross.png" title="Remove filter"></a>
          </span>
        </div>',
        $search->filter_species,
        $search->query_string,
        scalar(@params) ? ";" . join (';', map { $_."=".$hub->param($_) } @params ) . ";" : "", 
      ); 
    } elsif ($search->hit_count > 1 and $search->current_unit ne 'ensembl' and $search->current_index eq 'gene' and $search->species eq 'all') {
     
      my @species = @{ $search->get_facet_species };
      $html .= @species > 200 ? $self->_render_filter_autocomplete(\@species)
                              : $self->_render_filter_dropdown(\@species);
    }
  }

  if ($search->hit_count) {
  
    if($gtsearch) {
      my $unique_trees = {};     
      my $trees        = [];

      foreach my $hit ( grep { $_->{'featuretype'} eq 'Gene' } @{$search->get_all_hits} ) {
        # $dba is set to compara or compara_pan depending on $hub->param('pancompara'):
        return unless $dba;
        my $adaptor     = $dba->get_adaptor('Member') || return;
        my $member      = $adaptor->fetch_by_source_stable_id('ENSEMBLGENE', $hit->{'id'});
        my $all_trees = $dba->get_GeneTreeAdaptor->fetch_all_by_Member($member, -clusterset_id => 'default');
        foreach my $tree (sort {$a->stable_id cmp $b->stable_id} @$all_trees) {
          next if $unique_trees->{$tree->stable_id};
          $unique_trees->{$tree->stable_id} = 1;
          #Generating list of gene trees that contain any of the genes in the result:
          push @{$trees}, $tree; 
        }
      }
      # Count of the unique gene trees that contain any of the genes in the result:
      $tree_counter = scalar(keys %$unique_trees);

      my $current_page = (!$hub->param('page')) || ($tree_counter <= $pager->entries_per_page * $hub->param('page') - 10) ? 1 : $hub->param('page');       
      my ($lower_lim, $upper_lim) = (($current_page - 1) * $pager->entries_per_page, $tree_counter < $current_page * $pager->entries_per_page ? $tree_counter - 1 : $current_page * $pager->entries_per_page - 1);
     
      my $page_html;
      # Only gene trees that are in the scope of the current page are shown:
      foreach my $i ($lower_lim..$upper_lim) {
	$page_html .= $self->render_hit_gt($trees->[$i]);
      }
      # Pagination on the top of the page:
      $page_html = $self->render_pagination_gt($tree_counter, '1') . $page_html;
      $html .= $page_html;      
    } else {        
      $html .= $self->render_hit($_) for (@{$search->get_hits});
    }    
  }

  if ($gtsearch) {
    $html = $self->_render_results_message($tree_counter) . $html;    
    #my $site  = $hub->param('pancompara') ? 'Pan Compara' : ($search->species eq 'all' ? $search->current_sitename : $search->species);
    #$html = (sprintf "<h2>Your search for '%s' in %s returned %s %s%s.</h2>", $search->query_term, $site, $tree_counter, ucfirst(PL('Gene Tree', $tree_counter)), ($search->filter_species ? ' (filtered)' : '')) . $html;
  } else {  
    #$html = (sprintf "<h2>Your search for '%s' returned %s results.</h2>", $search->query_term, $search->{_hit_count_total}) . $html;
  }
  
  $html = qq{<div class="searchresults">\n$html\n</div>\n};  
  # Pagination on the bottom of the page:
  $html .= $gtsearch ? $self->render_pagination_gt($tree_counter) : $self->render_pagination; 
  # GeneTrees

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
  
  return qq{
    <p>Your search for <strong>'$query'</strong> returned no results</p>
    <p>
      Suggestions:
      <ul>
        <li>Make sure all terms are spelled correctly</li>
        $wildcards 
        $alt_searches
      </ul>
    </p>
    <br />
  }
}

sub _render_results_message {
  my $self = shift;
  my $search = $self->object->Obj; 
  my $pager = $search->pager;
  my $hub = $self->hub;

  # GeneTrees:
  my $gtsearch = $hub->param('gtsearch') || 0;
  my $tree_counter = shift || 0;
  my $current_page =  ($tree_counter <= $pager->entries_per_page * $hub->param('page') - 10) ? 1 : $hub->param('page') ? $hub->param('page') : 1;
  my ($range, $items, $site);

  if ($gtsearch) {
    $range = $tree_counter <= $pager->entries_per_page ? 
             $tree_counter 
             : 
             sprintf "%s-%s of %s", ($current_page - 1) * $pager->entries_per_page + 1, $tree_counter < $current_page * $pager->entries_per_page ? $tree_counter : $current_page * $pager->entries_per_page, $tree_counter;
    $site  = $hub->param('pancompara') ? 
             'Pan-taxonomic Compara' . ($search->filter_species ? ' (filtered)' : '') 
             :
             $search->species eq 'all' ? $search->current_sitename . ($search->filter_species ? ' (filtered)' : '') : $search->species;
  } else {
    $range = $search->hit_count <= $pager->entries_per_page ? $search->hit_count : sprintf "%s-%s of %s", $pager->first, $pager->last, $search->hit_count;
    $site  = $search->species eq 'all' ? $search->current_sitename . ($search->filter_species ? ' (filtered)' : '') : $search->species;
  }
  (my $index = $search->current_index) =~ s/_/ /;
  $items = $gtsearch ? ucfirst(PL('Gene Tree', $tree_counter)) : ucfirst(PL($index, $search->hit_count));
  # GeneTrees  

  my $html;
  if ((($search->hit_count > 0) && (!$gtsearch)) || $tree_counter) {
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
    $options .= qq{<option value="$_">$_</option>\n};
  }
  
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
}

sub _render_filter_autocomplete {
  my ($self, $species)  = @_;
  my $species_json_html = encode_entities(to_json($species));
  my $prompt            = 'Start typing a species name...';
  
  return qq{
    <div id="species_filter" class="js_panel">
      <input type="hidden" class="panel_type" value="SpeciesFilterAutocomplete" />
      <input type="hidden" id="species_autocomplete_json" value="$species_json_html" />
      <div class="search_filter">
        <span>
          Filter by species: 
          <input type="text" id="species_autocomplete" class="ui-autocomplete-input inactive" style="width:300px" title="$prompt" value="$prompt" />
        </span>
      </div>
    </div>
  };
}

# GeneTrees:
sub render_hit_gt {
   my ($self, $gene_tree) = @_;
   my $hub = $self->hub;
   my $table = EnsEMBL::Web::Document::TwoCol->new;
   my $link =  sprintf '<a class="name" href="%s">%s</a>', $hub->url({ species => 'Multi', type => 'GeneTree/Image', action => undef, gt => $gene_tree->stable_id, __clear => 1 }), $gene_tree->stable_id;

   ## some interesting stats...
   my $root_node = $gene_tree->root;

   $table->add_row("Alignment identity", ceil($gene_tree->get_value_for_tag('aln_percent_identity')).'%') if $gene_tree->get_tagvalue('aln_percent_identity');
   $table->add_row("Alignment length", $gene_tree->get_value_for_tag('aln_length') . 'aa') if $gene_tree->get_tagvalue('aln_length');
   $table->add_row("No. Genes", $gene_tree->get_tagvalue('gene_count')) if $gene_tree->get_tagvalue('gene_count');
   $table->add_row("No. Genomes", scalar(@{$gene_tree->get_all_taxa_by_member_source_name('ENSEMBLPEP')})) if scalar(@{$gene_tree->get_all_taxa_by_member_source_name('ENSEMBLPEP')});
   $table->add_row("Taxonomic range", $root_node->get_tagvalue('taxon_name')) if $root_node->get_tagvalue('taxon_name');

   my $info = $table->render;
   return qq{
    <div class="hit">
      <div class="title">
       $link
      </div>
      $info
    </div>
   }; 
}
# GeneTrees

sub render_hit {
  my ($self, $hit) = @_;
  
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  
  my $species = ucfirst($hit->{species});
  $species =~ s/_/ /;
  
  my $name = $hit->{name};
  
  my $table = EnsEMBL::Web::Document::TwoCol->new;

  if ($hit->{featuretype} eq 'Species') {

    $table->add_row("Taxonomy ID", $self->highlight($hit->{taxonomy_id}));
    $table->add_row("Assembly", $self->highlight($hit->{assembly_name}));
    $name = "<strong>$name</strong>";

  } elsif ($hit->{featuretype} eq 'Sequence region') {
    
    $table->add_row("Coordinate system", $hit->{coord_system});
    $table->add_row("Species", sprintf '<em><a href="%s">%s</a></em>', $hit->{species_path}, $self->highlight($species));
    $table->add_row("Location", qq{<a href="$hit->{species_path}/Location/View?r=$hit->{location};g=$hit->{id};db=$hit->{database}">$hit->{location}</a>});    
    $name = "<strong>$name</strong>";
  
  } else {

    $table->add_row("Description", ($self->highlight($hit->{description}) || 'n/a'));
    $table->add_row("Gene ID", sprintf('<a href="%s">%s</a>', $hit->{url}, $self->highlight($hit->{id})));
    $table->add_row("Species", sprintf '<em><a href="%s">%s</a></em>', $hit->{species_path}, $self->highlight($species));
    
    if ($hit->{location}) {
      $table->add_row("Location", sprintf '<a href="%s/Location/View?r=%s;g=%s;db=">%s</a>', $hit->{species_path}, $self->zoom_location($hit->{location}), $hit->{id}, $hit->{location}, $hit->{database});
    } 
    
    if ($hit->{gene_synonym}) {
      my %unique;
      foreach my $synonym (split /\n/, $hit->{gene_synonym}) { 
        (my $key = lc $synonym) =~ s/[^a-z0-9]/_/ig;
        (my $value = ucfirst $synonym) =~ s/-/ /g;
        $unique{$key} = $value;
      }
      $table->add_row("Synonyms", $self->highlight(join(', ', sort values %unique)));
    }
    
    # format the name
    $name =~ s/\[/\[ /;
    $name =~ s/\]$/ \]/;
    $name =~ s/^([^\s]+)(.*)$/<strong>$1<\/strong><span class="small">$2<\/span>/;
  }
  
  my $info = $table->render;
   
  return qq{
    <div class="hit">
      <div class="title">
        <a class="name" href="$hit->{url}">$name</a>
      </div>
      $info
    </div>
  };
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
  my ($region, $start, $end) = split /[:-]/, $location;
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

# GeneTrees:
sub render_pagination_gt {
    my $self   = shift;
    my $search = $self->object->Obj;

    my $tree_counter = shift || 0;
    my $top          = shift || 0;
    return if !$search->query_term or $tree_counter <= 10;
    my $hub = $self->hub;
    my @params        = grep { $_ =~ /gtsearch/ || $_ =~ /pancompara/ } $hub->param;
    my $entries_per_page = $search->pager->entries_per_page;
    my $current_page =  ($tree_counter <= $entries_per_page * $hub->param('page') - 10) ? 1 : $hub->param('page') ? $hub->param('page') : 1;
    my $last_page    = int($tree_counter / $entries_per_page) + 1;  
    my $previous_page = $current_page - 1;
    my $next_page    = $current_page + 1 > $last_page ? 0 : $current_page + 1;

    my $qs_params = $search->filter_species ? {filter_species => $search->filter_species} : {};
    my $query_string = $search->query_string($qs_params);

    my $html;

    if ( $previous_page) {
      $html .= sprintf( '<a class="prev" href="?page=%s;%s;%s">< Prev</a> ', $previous_page, $query_string, scalar(@params) ? join (';', map {$_."=".$hub->param($_)} @params ) . ";" : "");
    }

    foreach my $i (1..$last_page) {
      if( $i == $current_page ) {
        $html .= sprintf( '<span class="current">%s</span> ', $i );
      } elsif( $i < 5 || ($last_page - $i) < 4 || abs($i - $current_page + 1) < 4 ) {
	       $html .= sprintf( '<a href="?page=%s;%s;%s">%s</a>', $i, $query_string, scalar(@params) ? join (';', map {$_."=".$hub->param($_)} @params ) . ";" : "", $i );
      } else {
	       $html .= '..';
      }
    }

    $html =~ s/\.\.+/ ... /g;

    if ($next_page) {
      $html .= sprintf( '<a class="next" href="?page=%s;%s;%s">Next ></a> ', $next_page, $query_string, scalar(@params) ? join (';', map {$_."=".$hub->param($_)} @params ) . ";" : "");
    }
    my $vspace = $top ? '</br></br></br>' : ''; 
    return qq{<h4><div class="paginate">$html</div></h4>$vspace};
}
# GeneTrees

1;

