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

package EnsEMBL::Web::Document::HTML::SpeciesPage;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use HTML::Entities qw(encode_entities);
use Number::Format qw(format_number);

use base qw(EnsEMBL::Web::Component);
use parent qw(EnsEMBL::Web::Document::FileCache);

sub render {
  my $self = shift;
  return $self->read_html($SiteDefs::SPECIESPAGE_REFRESH_RATE);
}

sub make_html {
  my ($self, $class, $request) = @_;
  
  my $species_defs = EnsEMBL::Web::SpeciesDefs->new();
  my $html;

  # taxon order:
  my $species_info = {};

  foreach ($species_defs->valid_species) {
      $species_info->{$_} = {
        key        => $_,
        name       => $species_defs->get_config($_, 'SPECIES_BIO_NAME'),
        common     => $species_defs->get_config($_, 'SPECIES_COMMON_NAME'),
        scientific => $species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME'),
        group      => $species_defs->get_config($_, 'SPECIES_GROUP'),
        assembly   => $species_defs->get_config($_, 'ASSEMBLY_NAME'),
        clade      => $species_defs->get_config($_, 'SPECIES_SUBGROUP') || $species_defs->get_config($_, 'SPECIES_GROUP')
        };
  }

  my $labels       = $species_defs->TAXON_LABEL; ## sort out labels
  my (@group_order, %label_check);

  foreach my $taxon (@{$species_defs->TAXON_ORDER || []}) {
      my $label = $labels->{$taxon} || $taxon;
      push @group_order, $label unless $label_check{$label}++;
  }

  ## Sort species into desired groups
  my %phylo_tree;
  foreach (keys %$species_info) {
      my $group = $species_info->{$_}->{'group'} ? $labels->{$species_info->{$_}->{'group'}} || $species_info->{$_}->{'group'} : 'no_group';
      push @{$phylo_tree{$group}}, $_;
  }

  ## Output in taxonomic groups, ordered by common name
  my @taxon_species;
  my $taxon_gr;
  my @groups;

  foreach my $group_name (@group_order) {
      my $optgroup     = 0;
      my $species_list = $phylo_tree{$group_name};
      my @sorted_by_common;
      my $gr_name;
      if ($species_list && ref $species_list eq 'ARRAY' && scalar @$species_list) {
        @sorted_by_common = sort { $a cmp $b } @$species_list;
          if ($group_name eq 'no_group') {
            if (scalar @group_order) {
              $gr_name = "Other species";
            }
          } else {
            $gr_name = encode_entities($group_name);
          }
        push @groups, $gr_name if (!scalar(@groups)) || grep {$_ ne $gr_name } @groups ;
      }
      unshift @sorted_by_common, $gr_name if ($gr_name);
      push @taxon_species, @sorted_by_common;
  }
  # taxon order eof

  my %species;
  my $group = '';

  my $pre_species = $species_defs->get_config('MULTI', 'PRE_SPECIES');
  foreach my $sp (@taxon_species) { # (keys %$species_info) {
    $group =  $sp if exists $phylo_tree{$sp};
    next if exists $phylo_tree{$sp};

    my $info = {
      'dir'          => $sp,
      'status'       => 'live',
      'provider'     => $species_defs->get_config($sp, "PROVIDER_NAME") || '',
      'provider_url' => $species_defs->get_config($sp, "PROVIDER_URL") || '',
      'strain'       => $species_defs->get_config($sp, "SPECIES_STRAIN") || '',
      'group'        => $group,
      'taxid'        => $species_defs->get_config($sp, "TAXONOMY_ID") || '',
      'assembly'     => $species_defs->get_config($sp, "ASSEMBLY_NAME") || '',
      'common'       => $species_defs->get_config($sp, "SPECIES_COMMON_NAME"),
      'scientific'   => $species_defs->get_config($sp, "SPECIES_SCIENTIFIC_NAME"),
      'clade'        => $species_defs->get_config($sp, "SPECIES_SUBGROUP"),
      'coding_cnt'   => $species_defs->get_config($sp, "CODING_CNT"),
      'scaffolds_cnt'=> $species_defs->get_config($sp, "SCAFFOLDS_CNT"),
      'ref_length'   => $species_defs->get_config($sp, "REF_LENGTH"),
      'species_site' => $species_defs->ENSEMBL_SPECIES_SITE->{lc($sp)}
    };
    $info->{'status'} = 'pre' if($pre_species && exists $pre_species->{$sp});

    $species{$sp} = $info;
  }
  my $link_style = 'font-size:1.1em;font-weight:bold;text-decoration:none;font-style:italic;';

  my %groups = map {$species{$_}->{group} => 1} keys %species;
  
  $html .= qq{<div class="round-box home-box clear"><h2>Contents</h2><p>};
  foreach my $gr (@groups) {
    my $count = scalar grep { $species{$_}->{'group'} eq $gr } keys %species;
    $html .= qq{<a href="#$gr">$gr ($count)</a><br />};
  }
  $html .= qq{</p></div>};

  $html .= q(<div class="js_panel">
      <input class="panel_type" type="hidden" value="Piechart" />
      <input class="graph_config" type="hidden" name="stroke" value="'#999'" />
      <input class="graph_config" type="hidden" name="legend" value="false" />
      <input class="graph_dimensions" type="hidden" value="[15,15,14]" />
      <input class="graph_config" type="hidden" name="colors" value="['#254d71','#6f8da8','#c2d1df','#ffffff']" />
  ); 
  
  my $columns = [
    { key => 'species_name',     title => 'Species Name',     sort => 'string',         align => 'left', width => '15%' },
    { key => 'provider',         title => 'Provider',         sort => 'string',         align => 'left', width => '15%' },
    { key => 'assembly',         title => 'Assembly',         sort => 'string',         align => 'left', width => '10%' },
    { key => 'bioproject',       title => 'BioProject ID',    sort => 'string',         align => 'left', width => '10%' },
    { key => 'clade',            title => 'Clade',            sort => 'string',         align => 'left', width => '6%'  },
    { key => 'genome_browser',   title => 'Genome Browser',                             align => 'left', width => '8%'  },
    { key => 'BUSCO ANNOTATION', title => 'BUSCO ANNOTATION', sort => 'numeric_hidden', align => 'left', width => '4%', style => 'white-space: normal', class => "_no_export", help => "BUSCO is a method of measuring assembly and annotation quality, developed at the University of Geneva. BUSCO ANNOTATION is running at the protein level, assessing not only the assembly but also the annotation quality of a genome. In the genome assembly, we look for single-copy orthologs that are present in more than 90% of the animals. The percentages of complete, duplicated and partial genes recovered are reported." },
    { key => 'BUSCO ASSEMBLY',   title => 'BUSCO ASSEMBLY',   sort => 'numeric_hidden', align => 'left', width => '4%', style => 'white-space: normal', class => "_no_export", help => "BUSCO is a method of measuring assembly quality developed at the University of Geneva. In the genome assembly, we look for single-copy orthologs that are present in more than 90% of animals. The percentages of complete, duplicated and partial genes recovered are reported." },
    { key => 'OMARK Completeness', title => 'OMARK Completeness', sort => 'numeric_hidden', align => 'left', width =>     '4%', style => 'white-space: normal', class => "_no_export", help => "OMArk, developed at the Dessimoz Lab, University     of Lausanne (UNIL) is a method for proteome quality assessment based on fast placement of protein sequences within kn    own gene families. OMArk Completeness, similar to BUSCO Annotation, runs on the protein level, assessing not only the     assembly but also the annotation of a genome. The method assigns the genome's proteins to gene families (Hierarchical     Orthologous Groups - HOGs). It then defines the “conserved ancestral repertoire” of the query species and looks for HO    Gs defined at this ancestral level which cover more than 80% of the species in the clade. Since a HOG at the selected     taxonomic level represents a single ancestral gene, conserved HOGs are classified as one of the following: Single, Dup    licated and Missing." },
    { key => 'OMARK Consistency', title => 'OMARK Consistency', sort => 'numeric_hidden', align => 'left', width => '4%',     style => 'white-space: normal', class => "_no_export", help => "OMArk, developed at the Dessimoz Lab, University of La    usanne (UNIL) is a method for proteome quality assessment based on fast placement of protein sequences within known ge    ne families. OMArk Consistency, runs on the protein level, assessing not only the assembly but also the annotation of     a genome. The method assigns the genome's proteins gene families (Hierarchical Orthologous Groups - HOGs). It then def    ines the “lineage repertoire” of the query species consisting of all the HOGs from the conserved ancestral repertoire     plus those that originated later on and are still present in at least one species of the lineage. It uses this lineage     repertoire to classify proteins as: Consistent (placed into a HOG consistent with the lineage), Inconsistent (placed     into a HOG not consistent with the lineage), Contaminant (mapped to a lineage consistent with the lineage of a contami    nant species), Unknown (not placed into an existing HOG)." },
    { key => 'N50',              title => 'N50',              sort => 'numeric_hidden', align => 'left', width => '4%', help => "N50 is the length of the smallest contig such as the sum of the sequences larger than this contig covers half of the genome assembly." },
    { key => 'genome_size',     title => 'Genome Size'           , sort => 'numeric_hidden',         align => 'left', width => '4%', style => 'white-space: normal', 'hidden' => 1},
    { key => 'scaffold_size',   title => 'Number of Scaffolds'   , sort => 'numeric_hidden',         align => 'left', width => '4%', style => 'white-space: normal', 'hidden' => 1},
    { key => 'gene_size',       title => 'Number of Coding Genes', sort => 'numeric_hidden',         align => 'left', width => '4%', style => 'white-space: normal', 'hidden' => 1},
  ];

  my $j = 0;
  foreach my $gr (@groups) {  # (sort keys %groups) {
  
      my $table = $self->new_table($columns, [], { data_table => 1, sorting => ['species_name asc'], id => "species_table_$gr" });
      
      my @species = sort grep { $species{$_}->{'group'} eq $gr } keys %species;
                 
      my $total = scalar(@species);
     
      my $valid_species = 0;
      for(my $i = 0; $i < $total; $i++) {
      
        my @row;

        my $common = $species[$i];
        next unless $common;
        my $info = $species{$common};
  
        my $dir = $info->{'dir'};
  
        (my $name = $dir) =~ s/_/ /g;
        my $bioproj = $species_defs->get_config($dir, 'SPECIES_BIOPROJECT');
        $name =~ s/prj.*//; # Remove the BioProject ID from the name
        my $link_text = $info->{'scientific'}; # Use the scientific name from the database rather than the directory name

        if ($dir) {
          push(@row, sprintf(qq(<a href="/%s/Info/Index/" style="%s">%s</a>), $dir, $link_style, $link_text));
          my $provider = $info->{'provider'};
          my $url  = $info->{'provider_url'};
  
          my $strain = $info->{'strain'} ? "$info->{'strain'}" : '-';
          $name .= $strain;
          if ($provider) {
            if (ref $provider eq 'ARRAY') {
              my @urls = ref $url eq 'ARRAY' ? @$url : ($url);
              my $phtml;
              foreach my $pr (@$provider) {
                my $u = shift @urls;
                if ($u) {
                  $u = "http://$u" unless ($u =~ /http/);
                  $phtml .= qq{<a href="$u">$pr</a> &nbsp;};
                } else {
                  $phtml .= qq{$pr &nbsp;};
                }
              }
              push(@row, $phtml);
            } else {
              if ($url) {
                $url = "http://$url" unless ($url =~ /http/);
                push(@row, qq(<a href="$url">$provider</a>));
              } else {
                push(@row, $provider);
              }
            }
          }
        } else {
          push(@row, '&nbsp;');
        }
        my $assembly = $info->{'assembly'} ? "$info->{'assembly'}" : '';
        push(@row, $assembly);

        push(@row, qq{<a href="http://www.ebi.ac.uk/ena/data/view/$bioproj">$bioproj</a>});
       
        push(@row, $species_defs->TAXON_COMMON_NAME->{$info->{'clade'}} || $info->{'clade'});
       
        ## Genome Browser Links
        my $sample_data     = $species_defs->get_config($dir, 'SAMPLE_DATA');
        (my $jbrowse_region = $sample_data->{'LOCATION_PARAM'}) =~ s/-/../;
        my $jbrowse_url = sprintf("/jbrowse/browser/%s?loc=%s", lc($dir), $jbrowse_region);
        my $region_text = $sample_data->{'LOCATION_TEXT'};
        my $region_url  = $dir . '/Location/View?r=' . $sample_data->{'LOCATION_PARAM'};
        push(@row, sprintf('<a href="%s">JBrowse</a> | <a href="%s">Ensembl</a>', $jbrowse_url, $region_url));
 
        ## ParaSite: assembly stats - loaded in from a JSON file

        my $file = "/ssi/species/assembly_${dir}.json";
        my $content = (-e "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/$file") ? EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file) : '';

        if($content) {
          my $assembly = from_json($content);
          my @busco_list = qw(busco_annotation busco_assembly);
          for my $busco_type (@busco_list) {
            my $busco = $assembly->{$busco_type};
            if($busco) {
              my $busco_d = $busco->{D};
              my $busco_c = $busco->{C};
              my $busco_f = $busco->{F};
              push(@row, sprintf(q(
                <span class="hidden">%s</span>
                <div style="display: none;">
                  <input id="graph_data_item_%s" class="graph_data_ordered" type="hidden" value="[%s,%s,%s,%s]" />
                </div>
                <div id="graphHolder%s" style="width: 30px; height: 30px; margin: auto;" title="BUSCO Score: Complete: %s [Duplicated %s, Single %s], Fragmented %s"></div>
              ), $busco_c, $j, $busco_d / 100, ($busco_c - $busco_d) / 100, $busco_f / 100, (100 - $busco_c - $busco_f) / 100, $j, $busco_c, $busco_d, ($busco_c - $busco_d), $busco_f));
              $j++;
            } else {
              push(@row, '-');
            }
         }

            my $omark = $assembly->{'omark_completeness'};
            if($omark) {
              my $omark_s = $omark->{S};
              my $omark_d = $omark->{D};
              my $omark_m = $omark->{M};
              push(@row, sprintf(q(
                <span class="hidden">%s</span>
                <div style="display: none;">
                  <input id="graph_data_item_%s" class="graph_data_ordered" type="hidden" value="[%s,%s,%s]" />
                </div>
                <div id="graphHolder%s" style="width: 30px; height: 30px; margin: auto;" title="OMARK Completeness score: Single %s , Duplicated %s, Missing %s"></div>
              ),$omark_s, $j, $omark_d / 100,  $omark_m / 100, $omark_s / 100, $j, $omark_s,  $omark_m , $omark_d)) ;
              $j++;
            } else {
              push(@row, '-');
            }
            my $omark = $assembly->{'omark_consistency'};
            if($omark) {
              my $omark_s = $omark->{S};
              my $omark_p = $omark->{P};
              my $omark_f = $omark->{F};
              my $omark_t = $omark->{T};
              my $omark_u = $omark->{U};
              my $omark_e = $omark->{E};
              push(@row, sprintf(q(
                <span class="hidden">%s</span>
                <div style="display: none;">
                  <input id="graph_data_item_%s" class="graph_data_ordered" type="hidden" value="[%s,%s,%s,%.2f,%s]" />
                </div>
                <div id="graphHolder%s" style="width: 30px; height: 30px; margin: auto;" title="OMARK Consistency score: Consistent: %s [Complete %s, Partial %s, Fragmented %s], Inconsistent %.2f, Unknown %s"></div>
              ), $omark_e, $j, $omark_u / 100, (100 - ($omark_s + $omark_u + $omark_t)) / 100, $omark_f / 100, $omark_p / 100, $omark_e / 100, $j, $omark_s , $omark_e, $omark_p, $omark_f, (100 - ($omark_s + $omark_u + $omark_t)), $omark_u));
              $j++;
            } else {
              push(@row, '-');
            } 
          my $n50 = $assembly->{binned_scaffold_lengths}[500];
          push(@row, $n50 ? sprintf(qq(<span class="hidden">%s</span>%s), $n50, format_number($n50)) : '-');
        } else {
          push(@row, ('-', '-', '-'));
        }

        push (@row, sprintf(qq(<span class="hidden">%s</span>%s), $info->{'ref_length'}, format_number($info->{'ref_length'})));
        push (@row, sprintf(qq(<span class="hidden">%s</span>%s), $info->{'scaffolds_cnt'}, format_number($info->{'scaffolds_cnt'})));
        push (@row, sprintf(qq(<span class="hidden">%s</span>%s), $info->{'coding_cnt'}, format_number($info->{'coding_cnt'})));
        
        $table->add_row(\@row);
               
      }

      $html .= sprintf(qq{<div class="round-box home-box clear"><a name="%s"></a><h2>%s</h2><div>%s</div></div>}, $gr, $gr, $table->render);
  }

  $html .= '</div>';

  return $html;

}

1;
