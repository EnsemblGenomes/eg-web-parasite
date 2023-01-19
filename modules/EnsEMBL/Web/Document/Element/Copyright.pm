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

package EnsEMBL::Web::Document::Element::Copyright;

### Copyright notice for footer (basic version with no logos)

use strict;

sub content {
  my $self = shift;

  my $sd = $self->species_defs;

  return sprintf( qq(
  <div class="copyright">
    Release %d - %s
    <ul>
      <li><a href="https://www.ebi.ac.uk" target="_blank"><img src="/img/ebi_logo.png" title="European Molecular Biology Laboratory - European Bioinformatics Institute" /></a></li>
      <li><a href="https://www.gla.ac.uk" target="_blank"><img src="/img/gla_logo.png" title="University of Glasgow" /></a></li>
      <li><a href="https://www.ensembl.org" target="_blank"><img src="/img/empowered.png" title="Powered by Ensembl" /></a></li>
      <li><a href="https://www.ukri.org/councils/mrc" target="_blank"><img src="/img/mrc_logo.png" title="Medical Research Council" /></a></li>
      <li><a href="https://globalbiodata.org/scientific-activities/global-core-biodata-resources" target="_blank"><img src="/img/biodata_logo.png" title="Global Core Biodata Resources" /></a></li>
    </ul>
    WormBase ParaSite is funded by the <a href="https://www.ukri.org/councils/mrc/">UK Medical Research Council (MRC)</a> under grant number MR/S000453/1.
  </div>
  ), $sd->SITE_RELEASE_VERSION, $sd->SITE_RELEASE_DATE);
}

1;

