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

package EnsEMBL::Web::Document::HTML::SpeciesPage;

### Renders the content of the  "Find a species page" linked to from the SpeciesList module

use strict;
use warnings;
use Data::Dumper;
use HTML::Entities qw(encode_entities);
use EnsEMBL::Web::RegObj;

sub render {

  my ($class, $request) = @_;

  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $sitename = $species_defs->SITE_NAME;
  my $html;

  # check if we've got static content with species available resources and if so, use it
  # if not, use all the species page with no resources shown (red letters V P G A).
  my $content;
  my $filename = $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-'.$species_defs->GENOMIC_UNIT."/htdocs/info/data/resources.html";

  if (-e $filename) {
    open(my $fh, '<', $filename);
    {
        local $/;
        $content = <$fh>;
    }
    close($fh);
    return $content;
  }

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
  foreach my $species (@taxon_species) { # (keys %$species_info) {
    $group =  $species if exists $phylo_tree{$species};
    next if exists $phylo_tree{$species};

    my $common = $species_defs->get_config($species, "SPECIES_COMMON_NAME");
    my $info = {
      'dir'          => $species,
      'status'       => 'live',
      'provider'     => $species_defs->get_config($species, "PROVIDER_NAME") || '',
      'provider_url' => $species_defs->get_config($species, "PROVIDER_URL") || '',
      'strain'       => $species_defs->get_config($species, "SPECIES_STRAIN") || '',
      'group'        => $group,
      'taxid'        => $species_defs->get_config($species, "TAXONOMY_ID") || '',
      'assembly'     => $species_defs->get_config($species, "ASSEMBLY_NAME") || '',
      'scientific'   => $species_defs->get_config($species, "SPECIES_SCIENTIFIC_NAME"),
      'species_site' => $species_defs->ENSEMBL_SPECIES_SITE->{lc($species)}
    };
    $info->{'status'} = 'pre' if($pre_species && exists $pre_species->{$species});

    $species{$common} = $info;
  }
  my $link_style = 'font-size:1.1em;font-weight:bold;text-decoration:none;font-style:italic;';

  my %groups = map {$species{$_}->{group} => 1} keys %species;
  
  $html .= qq{<div class="round-box home-box clear"><h2>Contents</h2><p>};
  foreach my $gr (@groups) {
    my $count = scalar grep { $species{$_}->{'group'} eq $gr } keys %species;
    $html .= qq{<a href="#$gr">$gr ($count)</a><br />};
  }
  $html .= qq{</p></div>};
 
  foreach my $gr (@groups) {  # (sort keys %groups) {
      my @species = sort grep { $species{$_}->{'group'} eq $gr } keys %species;

      $html .= qq{<div class="round-box home-box clear"><a name="$gr"></a><h2>$gr</h2><table style="padding-bottom:10px"><tr><th>Species Name</th><th>Provider</th><th>Assembly</th><th>BioProject ID</th><th>Taxonomy ID</th></tr>};
                 
      my $total = scalar(@species);
     
      my $valid_species = 0;
      for(my $i = 0; $i < $total; $i++) {

      my $common = $species[$i];
      next unless $common;
      my $info = $species{$common};

      my $dir = $info->{'dir'};

      (my $name = $dir) =~ s/_/ /g;
      my $bioproj = $species_defs->get_config($dir, 'SPECIES_BIOPROJECT');
                  $name =~ s/prj.*//; # Remove the BioProject ID from the name
      my $link_text = $info->{'scientific'}; # Use the scientific name from the database rather than the directory name
      
      my $bgcol = $valid_species % 2 == 0 ? "#FFFFFF" : "#E5E5E5"; # Alternate the row background colour
                  $valid_species++;

      $html .= qq(<tr style="background-color:$bgcol">);

      if ($dir) {
        $html .= qq(<td style="width:250px"><a href="/$dir/Info/Index/" style="$link_style">$link_text</a></td>);
        $html .= ' (preview - assembly only)' if ($info->{'status'} eq 'pre');
        my $provider = $info->{'provider'};
        my $url  = $info->{'provider_url'};

        my $strain = $info->{'strain'} ? " $info->{'strain'}" : '';
        $name .= $strain;
        my $assembly = $info->{'assembly'} ? " $info->{'assembly'}" : '';
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
                $html .= qq{<td>$phtml</td><td style="width:150px">$assembly</td>};
              } else {
                if ($url) {
                  $url = "http://$url" unless ($url =~ /http/);
                  $html .= qq{<td style="width:250px"><a href="$url">$provider</a></td><td style="width:150px">$assembly</td>};
                } else {
                  $html .= qq{<td style="width:250px">$provider</td><td style="width:150px">$assembly</td>};
                }
              }
        } else {
          $html .= qq{<td style="width:250px"></td><td style="width:150px">$assembly</td>};
        }
        $html .= qq{<td style="width:100px"><a href="http://www.ebi.ac.uk/ena/data/view/$bioproj">$bioproj</a></td>};
        if($info->{'taxid'}){
         (my $uniprot_url = $species_defs->ENSEMBL_EXTERNAL_URLS->{'UNIPROT_TAXONOMY'}) =~ s/###ID###/$info->{taxid}/;
         $html .= sprintf('<td style="width:100px"><a href="%s">%s</a></td>', $uniprot_url, $info->{'taxid'});
        }
        $html .= '</td>';
      } else {
        $html .= '&nbsp;';
      }
      $html .= '</tr>';
      
      }

      $html .= '</tr></table></div>';
  }

  return $html;

}

1;
