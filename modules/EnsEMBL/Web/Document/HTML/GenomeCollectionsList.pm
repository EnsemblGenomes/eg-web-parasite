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

package EnsEMBL::Web::Document::HTML::GenomeCollectionsList;

use base qw(EnsEMBL::Web::Document::HTML::SpeciesList);

use strict;
use warnings;

sub render {
  return qq{
      <div id="species_list" class="js_panel home-search-flex">
        <input type="hidden" class="panel_type" value="SpeciesList" />
        <h3 class="first">Search for a genome</h3>
        <form id="species_autocomplete_form" action="/info/about/species.html" style="margin-bottom:5px" method="get">
          <div>
           <input name="search" type="text" id="species_autocomplete" class="ui-autocomplete-input inactive" style="width:95\%; margin: 0" placeholder="Start typing the name of a genome...">
          </div>
        </form>
        <p style="margin-bottom:0">
          e.g. type <b>bru</b> to find Brugia
        </p>
      </div>
  };
}

1;

