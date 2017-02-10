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

# $Id: HomePage.pm,v 1.69 2014-01-17 16:02:23 jk10 Exp $

package EnsEMBL::Web::Component::Info::HomePage;

use strict;

use EnsEMBL::Web::Document::HTML::HomeSearch;
use EnsEMBL::Web::DBSQL::ProductionAdaptor;
use EnsEMBL::Web::Component::GenomicAlignments;

use JSON;
use List::MoreUtils qw /first_index/;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->species;
  my $img_url      = $self->img_url;
  my $common_name  = $species_defs->SPECIES_COMMON_NAME;
  my $display_name = $species_defs->SPECIES_SCIENTIFIC_NAME;
  my $taxid        = $species_defs->TAXONOMY_ID;
  my $provider_link;

  my @species_parts = split('_', $species);
  my $species_short = "$species_parts[0]\_$species_parts[1]";

  if ($species_defs->PROVIDER_NAME && ref $species_defs->PROVIDER_NAME eq 'ARRAY') {
    my @providers;
    push @providers, map { $hub->make_link_tag(text => $species_defs->PROVIDER_NAME->[$_], url => $species_defs->PROVIDER_URL->[$_]) } 0 .. scalar @{$species_defs->PROVIDER_NAME} - 1;

    if (@providers) {
      $provider_link = join ', ', @providers;
    }
  }
  elsif ($species_defs->PROVIDER_NAME) {
    $provider_link = $hub->make_link_tag(text => $species_defs->PROVIDER_NAME, url => $species_defs->PROVIDER_URL);
  }

  my $html = '
    <div class="column-wrapper">  
        <div class="species-badge">';

  if(-e "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/${img_url}species/64/$species_short.png") {  # Check if the image exists
    $html .= qq(<img src="${img_url}species/64/$species_short.png" alt="" title="$common_name" />) unless $self->is_bacteria;
  }

  my $bioproject = $species_defs->SPECIES_BIOPROJECT;
  my $alias_list = $species_defs->SPECIES_ALTERNATIVE_NAME ? sprintf('(<em>%s</em>)', join(', ', @{$species_defs->SPECIES_ALTERNATIVE_NAME})) : undef; # Alternative names will appear in the order they are inserted to the meta table 
  $html .= qq(<h1><em>$display_name</em> $alias_list</h1>);

  $html .= '<p class="taxon-id">';
  $html .= sprintf('BioProject <a href="http://www.ncbi.nlm.nih.gov/bioproject/%s">%s</a> | ', $bioproject, $bioproject) if $bioproject;
  $html .= "Data Source $provider_link | " if $provider_link && $provider_link !~ /^Unknown$/;
  $html .= sprintf q{Taxonomy ID %s}, $hub->get_ExtURL_link("$taxid", 'UNIPROT_TAXONOMY', $taxid) if $taxid;
  $html .= '</p>';
  $html .= '</div>'; #species-badge

  $html .= '</div>'; # column-wrapper

  # Check for other genome projects for this species
  my @alt_projects = $self->_get_alt_projects($display_name, $species);
  my $alt_count = scalar(@alt_projects);
  my $alt_string = '<p>There ';
  $alt_string .= $alt_count == 1 ? "is $alt_count alternative genome project" : "are $alt_count alternative genome projects";
  $alt_string .= " for <em>$display_name</em> available in WormBase ParaSite: ";
  foreach my $alt (@alt_projects) {
    my $bioproj = $species_defs->get_config($alt, 'SPECIES_BIOPROJECT');
    my $provider = $species_defs->get_config($alt, 'PROVIDER_NAME');
    my $summary = $provider;
    $alt_string .= qq(<a href="/$alt/Info/Index/" title="$summary">$bioproj</a> );
  }
  $alt_string .= '</p>';

  # Check for other assembies from this project
  my @alt_projects = $self->_get_alt_strains($display_name, $species);
  my $alt_strain_count = scalar(@alt_projects);
  my $alt_strain_string = '<p>There ';
  $alt_strain_string .= $alt_strain_count == 1 ? "is $alt_strain_count alternative strain from this genome project" : "are $alt_strain_count alternative strains from this genome project";
  $alt_strain_string .= " for <em>$display_name</em> available in WormBase ParaSite: ";
  foreach my $alt (@alt_projects) {
    my $strain = $species_defs->get_config($alt, 'SPECIES_STRAIN');
    my $provider = $species_defs->get_config($alt, 'PROVIDER_NAME');
    my $summary = $provider;
    $alt_strain_string .= qq(<a href="/$alt/Info/Index/" title="$summary">$strain</a> );
  }
  $alt_strain_string .= '</p>';
    
  my $about_text = $self->_other_text('about', $species_short);
  $about_text = $self->_other_text('about', $species) unless $about_text;
  $about_text .= $alt_strain_string if $alt_strain_count > 0;
  $about_text .= $alt_string if $alt_count > 0;
  if ($about_text) {
    $html .= '<div class="column-wrapper"><div class="round-box home-box">'; 
    $html .= sprintf('<h2 data-generic-icon="i">About <em>%s</em> %s</h2>', $display_name, $alias_list);
    $html .= $about_text;
    $html .= '</div></div>';
  }

  ## ParaSite: add a link back to WormBase
  if ($hub->species_defs->ENSEMBL_SPECIES_SITE->{lc($species)} =~ /^wormbase$/i) {
    my $url = $hub->get_ExtURL_link('[View species at WormBase Central]', uc("$species\_URL"));
    $html .= qq(<div class="wormbase_panel">$url</div>);
  }
  ##

  my @left_sections;
  my @right_sections;
  
  push(@left_sections, $self->_assembly_text);

  push(@right_sections, $self->_navlinks_text) if $species_defs->SAMPLE_DATA && $species_defs->SAMPLE_DATA->{GENE_PARAM};
  
  push(@right_sections, $self->_assembly_stats);

  push(@left_sections, $self->_downloads_text);

  push(@left_sections, $self->_tools_text);

  push(@left_sections, $self->_publications_text) if $self->_other_text('publications', $species);

  push(@left_sections, $self->_resources_text) if $self->_other_text('resources', $species);
  
  $html .= '<div class="column-wrapper"><div class="column-two"><div class="column-padding">'; 
  for my $section (@left_sections){
    $html .= sprintf(qq{<div class="round-box home-box">%s</div>}, $section);
  }
  $html .= '</div></div><div class="column-two"><div class="column-padding">';
  for my $section (@right_sections) {
    $html .= sprintf(qq{<div class="round-box home-box">%s</div>}, $section);
  }
  $html .= '</div></div></div>';

  my $ext_source_html = $self->external_sources;
  $html .= '<div class="column-wrapper"><div class="round-box home-box unbordered">' . $ext_source_html . '</div></div>' if $ext_source_html;

  return $html;
}

sub _site_release {
  my $self = shift;
  return $self->hub->species_defs->SITE_RELEASE_VERSION;
}

sub _assembly_text {
  my $self             = shift;
  my $hub              = $self->hub;
  my $species_defs     = $hub->species_defs;
  my $species          = $hub->species;
  my $html;
  
  my $assembly_description = $self->_other_text('assembly', $species);
  $assembly_description =~ s/<h2>.*<\/h2>//; # Remove the header
  $assembly_description = 'Imported from <a href="http://www.wormbase.org">WormBase</a>' if($species_defs->PROVIDER_NAME =~ /^WormBase$/i && !$assembly_description);

  my $annotation_description = $self->_other_text('annotation', $species);
  $annotation_description =~ s/<h2>.*<\/h2>//; # Remove the header

  $html .= qq(<h2 data-conceptual-icon="d">Genome Assembly & Annotation</h2>);
  $html .= "<h3>Assembly</h3><p>$assembly_description</p>" if $assembly_description;
  $html .= "<h3>Annotation</h3><p>$annotation_description</p>" if $annotation_description;
  
  return $html;
}

sub _publications_text {
  my $self             = shift;
  my $hub              = $self->hub;
  my $species_defs     = $hub->species_defs;
  my $species          = $hub->species;
  my $html;

  my $text = $self->_other_text('publications', $species);
  $text =~ s/<h2>.*<\/h2>//; # Remove the header

  $html .= qq(<h2 data-functional-icon="j">Key Publications</h2>);
  $html .= "<p>$text</p>" if $text;

  return $html;

}

sub _navlinks_text {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $species         = $hub->species;
  my $sample_data     = $species_defs->SAMPLE_DATA;
  my $name            = $species_defs->SPECIES_COMMON_NAME;
  my $img_url         = $self->img_url;

  my $html = qq(<h2 data-generic-icon="]">Navigation</h2>);

  $html .= EnsEMBL::Web::Document::HTML::HomeSearch->new($hub)->render;

  $html .= '<div class="species-nav-icons">';

  # Karyotype image  
  if (@{$species_defs->ENSEMBL_CHROMOSOMES || []}) {
    $html .= sprintf('<div class="species-nav-icon"><a class="nodeco _ht" href="/%s/Location/Genome" title="Go to %s karyotype"><img src="%s96/karyotype.png" class="bordered" /><span>View karyotype</span></a></div>', $species, $name, $img_url);
  }

  # JBrowse genome browser link
  (my $jbrowse_region = $sample_data->{'LOCATION_PARAM'}) =~ s/-/../;
  my $jbrowse_url = sprintf("/jbrowse/browser/%s?loc=%s", lc($species), $jbrowse_region);
  $html .= sprintf('<div class="species-nav-icon"><a class="nodeco _ht" href="%s" title="Go to JBrowse"><img src="%s96/region.png" class="bordered" /><br /><span>Genome Browser (JBrowse)</span></a></div>', $jbrowse_url, $img_url);

  # Ensembl powered genome browser link
  my $region_text = $sample_data->{'LOCATION_TEXT'};
  my $region_url  = $species_defs->species_path . '/Location/View?r=' . $sample_data->{'LOCATION_PARAM'};
  $html .= sprintf('<div class="species-nav-icon"><a class="nodeco _ht" href="%s" title="Go to %s"><img src="%sgallery/location_view.png" class="bordered" /><br /><span>Genome Browser (Ensembl)</span></a></div>', $region_url, $region_text, $img_url);

  # Gene page
  my $gene_text = $sample_data->{'GENE_TEXT'};
  my $gene_url  = $species_defs->species_path . '/Gene/Summary?g=' . $sample_data->{'GENE_PARAM'};
  $html .= sprintf('<div class="species-nav-icon"><a class="nodeco _ht" href="%s" title="Go to gene %s"><img src="%s96/gene.png" class="bordered" /><br /><span>Example gene page</span></a></div>', $gene_url, $gene_text, $img_url);

  # Gene tree
  if($self->has_compara) {
    if($self->has_compara('GeneTree')) {
      my $tree_text = $sample_data->{'GENE_TEXT'};
      my $tree_url  = $species_defs->species_path . '/Gene/Compara_Tree?g=' . $sample_data->{'GENE_PARAM'};
      $html .= sprintf('<div class="species-nav-icon"><a class="nodeco _ht" href="%s" title="Go to gene tree for %s"><img src="%s96/compara.png" class="bordered" /><span>Example gene tree</span></a></div>', $tree_url, $tree_text, $img_url);
    } else {
      $html .= sprintf('<div class="species-nav-icon"><span class="nodeco _ht" title="Genome not included in comparative genomics"><img src="%s96/compara.png" class="bordered" /><span>Example gene tree</span></span></div>', $img_url);
    }
  }

  $html .= '</div>';
  return $html; 
}

# ParaSite specific Downloads section
sub _downloads_text {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->species;
  my $rel          = $species_defs->SITE_RELEASE_VERSION;

  (my $sp_name = $species) =~ s/_/ /;
  my $sp_dir =lc($species);
  my $common = $species_defs->get_config($species, 'SPECIES_COMMON_NAME');
  my $scientific = $species_defs->get_config($species, 'SPECIES_SCIENTIFIC_NAME');

  my $ftp_base_path_stub = $species_defs->SITE_FTP . "/releases/WBPS$rel";

  return unless my ($bioproject) = $species =~ /^.*?_.*?_(.*)$/;
  $bioproject = $species_defs->get_config($species, 'SPECIES_FTP_GENOME_ID');
  my $species_lower = lc(join('_',(split('_', $species))[0..1])); 

  my $html = '<h2 data-functional-icon="=">Downloads</h2>';
  $html .= '<ul>';
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic.fa.gz\">Genomic Sequence (FASTA)</a></li>";
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic_masked.fa.gz\">Hard-masked Genomic Sequence (FASTA)</a></li>";
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.genomic_softmasked.fa.gz\">Soft-masked Genomic Sequence (FASTA)</a></li>";
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.annotations.gff3.gz\">Annotations (GFF3)</a></li>";
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.protein.fa.gz\">Proteins (FASTA)</a></li>";
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.mRNA_transcripts.fa.gz\">Full-length transcripts (FASTA)</a></li>";
  $html .= "<li><a href=\"$ftp_base_path_stub/species/$species_lower/$bioproject/$species_lower.$bioproject.WBPS$rel.CDS_transcripts.fa.gz\">CDS transcripts (FASTA)</a></li>";
  $html .= '</ul>';
  
  return $html;
}

# ParaSite specific Tools section
sub _tools_text {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $species         = $hub->species;
  my $img_url         = $self->img_url;
  my $html;

  $html .= '<h2 data-functional-icon="t">Tools</h2>';

  $html .= '<ul>';
  my $blast_url = $hub->url({'type' => 'Tools', 'action' => 'Blast', __clear => 1});
  $html .= qq(<li><a href="$blast_url">Search for sequences in the genome and proteome using BLAST</a></li>);
  $html .= qq(<li><a href="/biomart/martview">Work with lists of data using the WormBase ParaSite BioMart data-mining tool</a></li>);
  $html .= qq(<li><a href="/rest">Programatically access WormBase ParaSite data using the REST API</a></li>);
  my $new_vep = $species_defs->ENSEMBL_VEP_ENABLED;
  $html .= sprintf(
    qq(<li><a href="%s">Predict the effects of variants using the Variant Effect Predictor</a></li>),
    $hub->url({'__clear' => 1, $new_vep ? qw(type Tools action VEP) : qw(type UserData action UploadVariations)}),
    $new_vep ? '' : 'modal_link ',
    $self->img_url
  );
  $html .= '</ul>';

}

# ParaSite specific Resources section
sub _resources_text {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $species         = $hub->species;
  my $img_url         = $self->img_url;
  my $sample_data     = $species_defs->SAMPLE_DATA;
  my $ensembl_version = $species_defs->ENSEMBL_VERSION;
  my $site            = $species_defs->ENSEMBL_SITETYPE;
  my $html;
  my $imported_resources = $self->_other_text('resources', $species);
  $imported_resources =~ s/<h2>.*<\/h2>//; # Remove the header

  $html .= '<h2>Resources</h2>';

  $html .= $imported_resources;

  return $html;
  
}

# ParaSite: assembly stats
sub _assembly_stats {
  my $self = shift;
  my $hub = $self->hub;
  my $sp = $hub->species;

  my $stats_table = $self->species_stats;
  my $html = qq(
    <div class="js_panel">
      <h2 data-functional-icon="z">Assembly Statistics</h2>
      $stats_table
      <input type="hidden" class="panel_type" value="AssemblyStats" />
      <input type="hidden" id="assembly_file" value="/Multi/Ajax/assembly_stats?species=$sp" />
      <div id="assembly_stats"></div>
      <p style="font-size: 10pt"><a href="/info/Browsing/assembly_quality.html">Learn more about this widget in our help section</a></p>
      <p style="font-size: 8pt">This widget has been derived from the <a href="https://github.com/rjchallis/assembly-stats">assembly-stats code</a> developed by the Lepbase project at the University of Edinburgh</p>
    </div>
  );

}



# EG

=head2 _other_text

  Arg[1] : tag name to seek
  Arg[2] : species internal name e.g. Caenorhabditis_elegans
  Return : text from htdocs/ssi/species/about_[species].html bounded by the string: <!-- {tag} -->

=cut

sub _other_text {
  my ($self, $tag, $species) = @_;
  my $file = $tag eq 'about' ? "/ssi/species/about_species_${species}.html" : "/ssi/species/about_assembly_${species}.html";
  my $content = (-e "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/$file") ? EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file) : '';
  my ($other_text) = $content =~ /^.*?<!--\s*\{$tag\}\s*-->(.*)<!--\s*\{$tag\}\s*-->.*$/ms;
  #ENSEMBL-2535 strip subs
  $other_text =~ s/(\{\{sub_[^\}]*\}\})//mg;
  return $other_text;
}

=head2 _has_compara

  Arg[1]     : Database to check, 'compara' or 'compara_pan_ensembl'
  Arg[2]     : Optional - Type of object to check for, e.g. GeneTree, Family
  Description: Check for existence of Compara data for the sample gene
  Returns    : 0, 1, or number of objects

=cut

sub _has_compara {
  my $self           = shift;
  my $db_name        = shift || 'compara';             
  my $object_type    = shift;                           
  my $hub            = $self->hub;
  my $species_defs   = $hub->species_defs;
  my $sample_gene_id = $species_defs->SAMPLE_DATA ? $species_defs->SAMPLE_DATA->{'GENE_PARAM'} : '';
  my $db             = $hub->database($db_name);
  my $has_compara    = 0;
  
  if ($db) {
    if ($object_type) { 
      if ($sample_gene_id) {
        # check existence of a specific data type for the sample gene
        my $member_adaptor = $db->get_GeneMemberAdaptor;
        my $object_adaptor = $db->get_adaptor($object_type);
  
        if (my $member = $member_adaptor->fetch_by_stable_id($sample_gene_id)) {
          if ($object_type eq 'Family' and $self->is_bacteria) {
            $member = $member->get_all_SeqMembers->[0];
          }
          my $objects = $object_type eq 'Family' ? $object_adaptor->fetch_all_by_GeneMember($member) : $object_adaptor->fetch_all_by_Member($member);
          $has_compara = @$objects;
        }
      }
    } else { 
      # no object type specified, simply check if this species is in the db
      my $genome_db_adaptor = $db->get_GenomeDBAdaptor;
      my $genome_db;
      eval{ 
        $genome_db = $genome_db_adaptor->fetch_by_registry_name($hub->species);
      };
      $has_compara = $genome_db ? 1 : 0;
    }
  }

  return $has_compara;  
}

# shortcuts
sub has_compara     { 
  my $self = shift;
  return $self->_has_compara('compara', @_); 
}

# /EG

# ParaSite

sub _get_alt_projects {
  my ($self, $species, $current) = @_;
  my $species_defs = EnsEMBL::Web::SpeciesDefs->new();
  my @species_list = ();
  foreach ($species_defs->valid_species) {
        if ($species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME') eq $species && $_ ne $current && $species_defs->get_config($_, 'SPECIES_BIOPROJECT') ne $species_defs->get_config($current, 'SPECIES_BIOPROJECT')) {
          push(@species_list, $_);
        }
  }
  return sort(@species_list);
}

sub _get_alt_strains {
  my ($self, $species, $current) = @_;
  my $species_defs = EnsEMBL::Web::SpeciesDefs->new();
  my @species_list = ();
  foreach ($species_defs->valid_species) {
        if ($species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME') eq $species && $species_defs->get_config($_, 'SPECIES_STRAIN') ne $species_defs->get_config($current, 'SPECIES_STRAIN') && $species_defs->get_config($_, 'SPECIES_BIOPROJECT') eq $species_defs->get_config($current, 'SPECIES_BIOPROJECT')) {
          push(@species_list, $_);
        }
  }
  return sort(@species_list);
}

# /ParaSite

sub _add_gene_counts {
  my ($self,$genome_container,$sd,$cols,$options,$tail,$our_type) = @_;

  my @order           = qw(coding_cnt noncoding_cnt noncoding_cnt/s noncoding_cnt/l noncoding_cnt/m pseudogene_cnt transcript);
  my @suffixes        = (['','~'], ['r',' (incl ~ '.$self->glossary_helptip('readthrough', 'Readthrough').')']);
  my $glossary_lookup = {
    'coding_cnt'        => 'Protein coding',
    'noncoding_cnt/s'   => 'Small non coding gene',
    'noncoding_cnt/l'   => 'Long non coding gene',
    'pseudogene_cnt'    => 'Pseudogene',
    'transcript'        => 'Transcript',
  };

  my @data;
  foreach my $statistic (@{$genome_container->fetch_all_statistics()}) {
    my ($name,$inner,$type) = ($statistic->statistic,'','');
    if($name =~ s/^(.*?)_(r?)(a?)cnt(_(.*))?$/$1_cnt/) {
      ($inner,$type) = ($2,$3);
      $name .= "/$5" if $5;
    }
    next unless $type eq $our_type;
    my $i = first_index { $name eq $_ } @order;
    next if $i == -1;
    ($data[$i]||={})->{$inner} = $self->thousandify($statistic->value);
    $data[$i]->{'_key'} = $name;
    $data[$i]->{'_name'} = $statistic->name if $inner eq '';
    $data[$i]->{'_sub'} = ($name =~ m!/!);
  }

  my $counts = $self->new_table($cols, [], $options);
  foreach my $d (@data) {
    my $value = '';
    foreach my $s (@suffixes) {
      next unless $d->{$s->[0]};
      $value .= $s->[1];
      $value =~ s/~/$d->{$s->[0]}/g;
    }
    next unless $value;
    my $class = '';
    $class = 'row-sub' if $d->{'_sub'};
    my $key = $d->{'_name'};
    $key = $self->glossary_helptip(qq(<span style="font-weight: bold">$d->{'_name'}</span>), $glossary_lookup->{$d->{'_key'}});
    $counts->add_row({ name => $key, stat => $value, options => { class => $class }});
  }
  return "<h3>Gene counts$tail</h3>".$counts->render;
}

1;
