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

package EnsEMBL::Web::Document::Element::ToolLinks;

use strict;

sub links {
  my $self  = shift;
  my $hub   = $self->hub;
  my $sd    = $self->species_defs;
  my @links;

  push @links, 'specieslist',   '<a class="constant" href="/info/about/species.html">Species List</a>';
  push @links, 'blast', sprintf '<a class="constant" href="%s">BLAST</a>', $self->hub->url({'species' => '', 'type' => 'Tools', 'action' => 'Blast'}) if $sd->ENSEMBL_BLAST_ENABLED;
  push @links, 'tools',         '<a class="constant" href="/tools.html">Tools</a>';
  push @links, 'downloads',     '<a class="constant" href="/info/access/ftp/index.html">Downloads</a>';

  return \@links;
}

1;

