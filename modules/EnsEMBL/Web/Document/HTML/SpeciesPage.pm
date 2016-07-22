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

package EnsEMBL::Web::Document::HTML::SpeciesPage;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use HTML::Entities qw(encode_entities);
use Number::Format qw(format_number);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Component);

sub render {

  my ($self, $class, $request) = @_;

  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
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
        assembly   => $species_defs->get_config($_, 'ASSEMBLY_NAME')
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
    { key => 'species_name',  title => 'Species Name',   sort => 'string',         align => 'left', width => '15%' },
    { key => 'provider',      title => 'Provider',       sort => 'string',         align => 'left', width => '15%' },
    { key => 'assembly',      title => 'Assembly',       sort => 'string',         align => 'left', width => '10%' },
    { key => 'bioproject',    title => 'BioProject ID',  sort => 'string',         align => 'left', width => '10%' },
    { key => 'cegma',         title => 'CEGMA',          sort => 'numeric_hidden', align => 'left', width => '4%', class => "_no_export"  },
    { key => 'busco',         title => 'BUSCO',          sort => 'numeric_hidden', align => 'left', width => '4%', class => "_no_export"  },
    { key => 'n50',           title => 'N50',            sort => 'numeric_hidden', align => 'left', width => '4%'  },
  ];

  my $j = 0;
  foreach my $gr (@groups) {  # (sort keys %groups) {
  
      my $table = $self->new_table($columns, [], { data_table => 1, sorting => ['species_name asc'], id => "species_table_$gr" });
      
      my @species = sort grep { $species{$_}->{'group'} eq $gr } keys %species;
                 
      my $total = scalar(@species);
     
      my $valid_species = 0;
      for(my $i = 0; $i < $total; $i++) {
      
        my @col_data;

        my $common = $species[$i];
        next unless $common;
        my $info = $species{$common};
  
        my $dir = $info->{'dir'};
  
        (my $name = $dir) =~ s/_/ /g;
        my $bioproj = $species_defs->get_config($dir, 'SPECIES_BIOPROJECT');
        $name =~ s/prj.*//; # Remove the BioProject ID from the name
        my $link_text = $info->{'scientific'}; # Use the scientific name from the database rather than the directory name

        if ($dir) {
          push(@col_data, sprintf(qq(<a href="/%s/Info/Index/" style="%s">%s</a>), $dir, $link_style, $link_text));
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
              push(@col_data, $phtml);
            } else {
              if ($url) {
                $url = "http://$url" unless ($url =~ /http/);
                push(@col_data, qq(<a href="$url">$provider</a>));
              } else {
                push(@col_data, $provider);
              }
            }
          }
        } else {
          push(@col_data, '&nbsp;');
        }
        my $assembly = $info->{'assembly'} ? "$info->{'assembly'}" : '';
        push(@col_data, $assembly);

        push(@col_data, qq{<a href="http://www.ebi.ac.uk/ena/data/view/$bioproj">$bioproj</a>});
        
        ## ParaSite: assembly stats - loaded in from a JSON file

        my $file = "/ssi/species/assembly_${dir}.json";
        my $content = (-e "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/$file") ? EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file) : '';

        if($content) {
          my $assembly = from_json($content);
         
          my $cegma_comp = $assembly->{cegma_complete};
          my $cegma_part = $assembly->{cegma_partial} - $assembly->{cegma_complete};
          if($cegma_comp >= 0 && $cegma_part >= 0) {
          push(@col_data, sprintf(qq(
            <span class="hidden">%s</span>
            <div style="display: none;">
              <input id="graph_data_item_%s" class="graph_data_ordered" type="hidden" value="[%s,%s,%s,%s]" />
            </div>
            <div id="graphHolder%s" style="width: 30px; height: 30px; margin: auto;" title="CEGMA Score: Complete %s; Partial %s"></div>
          ), $cegma_comp, $j, 0, $cegma_comp / 100, $cegma_part  / 100, (100 - $cegma_comp - $cegma_part) / 100, $j, $cegma_comp, ($cegma_comp + $cegma_part)));
          $j++;
          } else {
            push(@col_data, '-');
          }

          my $busco = $assembly->{busco};
          if($busco) {
            my $busco_d = $busco->{D};
            my $busco_c = $busco->{C};
            my $busco_f = $busco->{F};
            push(@col_data, sprintf(q(
              <span class="hidden">%s</span>
              <div style="display: none;">
                <input id="graph_data_item_%s" class="graph_data_ordered" type="hidden" value="[%s,%s,%s,%s]" />
              </div>
              <div id="graphHolder%s" style="width: 30px; height: 30px; margin: auto;" title="BUSCO Score: D %s, C %s, F %s"></div>
            ), $busco_c, $j, $busco_d / 100, ($busco_c - $busco_d) / 100, $busco_f / 100, (100 - $busco_c - $busco_f) / 100, $j, $busco_d, $busco_c, $busco_f));
            $j++;
          } else {
            push(@col_data, '-');
          }
          
          my $n50 = $assembly->{binned_scaffold_lengths}[500];
          push(@col_data, $n50 ? sprintf(qq(<span class="hidden">%s</span>%s), $n50, format_number($n50)) : '-');
        } else {
          push(@col_data, ('-', '-', '-'));
        }
        
        $table->add_row(\@col_data);
               
      }

      $html .= sprintf(qq{<div class="round-box home-box clear"><a name="%s"></a><h2>%s</h2><div>%s</div></div>}, $gr, $gr, $table->render);
  }

  $html .= '</div>';

  return $html;

}

1;
