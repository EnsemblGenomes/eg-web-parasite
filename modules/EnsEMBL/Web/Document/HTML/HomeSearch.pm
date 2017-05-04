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

package EnsEMBL::Web::Document::HTML::HomeSearch;

### Generates the search form used on the main home page and species
### home pages, with sample search terms taken from ini files

use strict;

use base qw(EnsEMBL::Web::Document::HTML);

use EnsEMBL::Web::Form;

sub render {
  my $self = shift;
  
  my $hub                 = $self->hub;
  my $species_defs        = $hub->species_defs;
  my $page_species        = $hub->species || 'Multi';
  my $species_name        = $page_species eq 'Multi' ? '' : $hub->species;
  my $species_display     = $page_species eq 'Multi' ? '' : $species_defs->DISPLAY_NAME;
  my $search_url          = $species_defs->ENSEMBL_WEB_ROOT . "$page_species/Search/Results";

  my $html = qq{<form action="$search_url" method="GET"><div class="search" style="width: 420px; border: 1px solid lightgrey"><input type="hidden" name="site" value="ensemblthis" /><input type="hidden" name="filter_species" value="$species_name" /><input type="text" id="q" name="q" class="query" style="width: 378px" required placeholder="Search $species_display&hellip;" /><input type="submit" value="1"/></div></form>};

  return sprintf '<div id="SpeciesSearch" class="js_panel home-search-flex"><input type="hidden" class="panel_type" value="SearchBox" />%s</div>', $html;
}

1;
