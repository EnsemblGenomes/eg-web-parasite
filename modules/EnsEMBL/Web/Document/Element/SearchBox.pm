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

package EnsEMBL::Web::Document::Element::SearchBox;

### Generates small search box (used in top left corner of pages)

use strict;

sub content {
  my $self            = shift;
  my $img_url         = $self->img_url;
  my $species         = $self->species;
  my $species_common  = $self->species_defs->SPECIES_COMMON_NAME;
  my $search_url      = sprintf '%s%s/psychic', $self->home_url, $species || 'Multi';
  my $search_options  = qq(<input type="hidden" name="site" value="ensemblunit" />);
  my $species_dropdown = qq(<select name="site"><option value="ensemblunit">All species</option><option value="ensemblthis" selected="selected">%s</option></select>);

  return qq(
    <div id="searchPanel" class="js_panel">
      <input type="hidden" class="panel_type" value="SearchBox" />
      <form action="$search_url">
        <div class="search print_hide">
            <label class="hidden" for="se_q">Search terms</label>
            <input class="query" id="se_q" type="text" name="q" data-role="none" placeholder="Search WormBase ParaSite..." />
            <input type="submit" value="1" />
        </div>
      </form>
    </div>
  );
}

1;


