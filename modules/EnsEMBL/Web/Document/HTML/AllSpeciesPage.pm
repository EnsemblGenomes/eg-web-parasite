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

package EnsEMBL::Web::Document::HTML::AllSpeciesPage;

### Renders the content of the  species section on the homepage

use strict;
use warnings;
use Data::Dumper;
use HTML::Entities qw(encode_entities);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {

  my ($class, $request) = @_;

  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $sitename = $species_defs->SITE_NAME;
  my $species_info = {};
  
  # Get a list of group names
  my $labels       = $species_defs->TAXON_LABEL; ## sort out labels
  my (@group_order, %label_check);
  foreach my $taxon (@{$species_defs->TAXON_ORDER || []}) {
      my $label = $labels->{$taxon} || $taxon;
      push @group_order, $label unless $label_check{$label}++;
  }
  
  my $html = qq(<div class="column-wrapper">);
  $html .= qq{<div class="round-box home-box clear scroll-box species-box js_panel"><input type="hidden" class="panel_type" value="SpeciesExpander" /><h2 data-functional-icon="1">Find a genome</h2>};
  
  # Loop through each group
  foreach my $group (@group_order) {

      my $display = defined($species_defs->TAXON_COMMON_NAME->{$group}) ? $species_defs->TAXON_COMMON_NAME->{$group} : $group;
      
      # Note the classes and ids which are used by the jQuery to show (i.e. expand) these divs
  	  $html .= qq(<div class="expanding-parent" id="parent-$group">);
  	  $html .= qq(<div class="expanding-header" id="header-$group"><span id="key-plus-$group">[+]</span><span id="key-minus-$group" style="display: none">[-]</span>&nbsp;$display</div>);
  	  $html .= qq(<div class="expanding-area" id="expand-$group">);
  	  
  	  # Check for the presence of any sub-groups
      my @subgroups;
      foreach my $taxon (@{$species_defs->TAXON_SUB_ORDER->{$group} || ['parent']}) {
        push @subgroups, $taxon;
      }
  	  
  	  foreach my $subgroup (@subgroups) {
		  if($subgroup ne 'parent') {
		      my $display = defined($species_defs->TAXON_COMMON_NAME->{$subgroup}) ? $species_defs->TAXON_COMMON_NAME->{$subgroup} : $subgroup;
			  $html .= qq(<div class="expanding-parent" id="parent-$subgroup">);
			  $html .= qq(<div class="expanding-header" id="header-$subgroup"><span id="key-plus-$subgroup">[+]</span><span id="key-minus-$subgroup" style="display: none">[-]</span>&nbsp;$display</div>);
			  $html .= qq(<div class="expanding-area" id="expand-$subgroup">);
		  }
		  
		  # Group the genome projects by species name
		  my %species = ();
		  my %providers = ();
		  # Is this a multi-taxon group?
		  my @taxons = @{$species_defs->TAXON_MULTI->{$subgroup} || [$subgroup]};
		  foreach my $taxon (@taxons) {
			  foreach ($species_defs->valid_species) {
				next unless defined($species_defs->get_config($_, 'SPECIES_GROUP'));
				if($taxon eq 'parent') {
				  next unless $species_defs->get_config($_, 'SPECIES_GROUP') eq $group;
				} else {
				  next unless $species_defs->get_config($_, 'SPECIES_SUBGROUP') eq $taxon;
				}
				my $common = $species_defs->get_config($_, 'SPECIES_COMMON_NAME');
				next unless $common;
				my $scientific = $species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME');
				push(@{$species{$scientific}}, $_);
				$providers{$_} = $species_defs->get_config($_, 'PROVIDER_NAME');
			  }
		  }
  
		  # Print the species
		  my $i = 0;
		  $html .= '<ul>';
		  foreach my $scientific (sort(keys(%species))) {
			$html .= '<li class="home-species-box">';
			my $species_url = scalar(@{$species{$scientific}}) == 1 ? "/@{$species{$scientific}}[0]/Info/Index/" : "/@{$species{$scientific}}[0]/Info/SpeciesLanding/";  # Only show a URL to the species landing page if there is more than one genome project
			$html .= qq(<span class="home-species"><a href="$species_url" class="species-link">$scientific</a></span><br /><span class="home-bioproject">);
			my $i = 0;
			foreach my $project (sort(@{$species{$scientific}})) {
				$i++;
				my @name_parts = split("_", $project);
				my $bioproject = uc($name_parts[2]);
                                next if $bioproject eq ''; # Skip if there is no BioProject (as this is a species imported from WormBase and we don't want to link to it from here)
				my $summary = "$providers{$project} genome project";
				$html .= qq(<a href="/$project/Info/Index/" title="$summary">$bioproject</a>);
				if($i < scalar(@{$species{$scientific}})) { $html .= ' | '; }
			}
			$html .= '</span>';
			$html .= '</li>';
		  }
		  $html .= '</ul>';
		  
		  if($subgroup ne 'parent') {
			  $html .= qq(</div></div>);
		  }
		  	  
	  }
	  
	  $html .= qq(</div></div>);
  
  }
  
  $html .= qq(</div></div>);

  return $html;

}

1;
