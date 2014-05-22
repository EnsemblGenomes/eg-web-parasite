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

  # check if we've got static content with species available resources and if so, use it
  # if not, use all the species page with no resources shown (red letters V P G A).
  my $content;
  my $species_info = {};
  
  my $html = qq(<div class="column-wrapper">);
  $html .= qq{<div class="round-box tinted-box clear scroll-box"><a name="all"></a><h2>All Species</h2><table style="padding-bottom:10px"><tr><th>Species Name</th><th>Provider</th><th>Assembly</th><th>BioProject ID</th><th>Taxonomy ID</th></tr>};

  my $i = 0;
  foreach ($species_defs->valid_species) {
  	$i++;
  
	my $common = $species_defs->get_config($_, "SPECIES_COMMON_NAME");
	next unless $common;
    $species_info->{$_} = {
        key            => $_,
        name           => $species_defs->get_config($_, 'SPECIES_BIO_NAME'),
        common         => $species_defs->get_config($_, 'SPECIES_COMMON_NAME'),
        scientific     => $species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME'),
        group          => $species_defs->get_config($_, 'SPECIES_GROUP'),
        assembly   	   => $species_defs->get_config($_, 'ASSEMBLY_NAME'),
    	dir            => $_,
      	status         => 'live',
      	provider       => $species_defs->get_config($_, 'PROVIDER_NAME') || '',
      	provider_url   => $species_defs->get_config($_, 'PROVIDER_URL') || '',
      	strain         => $species_defs->get_config($_, 'SPECIES_STRAIN') || '',
     	taxid          => $species_defs->get_config($_, 'TAXONOMY_ID') || '',
     	assembly       => $species_defs->get_config($_, 'ASSEMBLY_NAME') || ''
    };

	my $link_style = 'font-size:1.1em;font-weight:bold;text-decoration:none;';

	my $info = $species_info->{$_};
	my $dir = $info->{'dir'};

	(my $name = $dir) =~ s/_/ /g;
	my ($bioproj) = $name =~ m/(prj.*)/; # Get the BioProject ID
	$bioproj = uc($bioproj);
	$name =~ s/prj.*//; # Remove the BioProject ID from the name
	my $link_text = $info->{'scientific'}; # Use the scientific name from the database rather than the directory name
		  
	my $bgcol = $i % 2 == 0 ? "#FFFFFF" : "#E5E5E5"; # Alternate the row background colour

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
			  $html .= qq{<td>$phtml</td><td style="width:100px">$assembly</td>};
			} else {
			  if ($url) {
				  $url = "http://$url" unless ($url =~ /http/);
				  $html .= qq{<td style="width:100px"><a href="$url">$provider</a></td><td style="width:100px">$assembly</td>};
			  } else {
				  $html .= qq{<td style="width:100px">$provider</td><td style="width:100px">$assembly</td>};
			  }
			}
		} else {
			$html .= qq{<td style="width:100px"></td><td style="width:100px">$assembly</td>};
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

  $html .= '</tr></table></div></div>';

  return $html;

}

1;
