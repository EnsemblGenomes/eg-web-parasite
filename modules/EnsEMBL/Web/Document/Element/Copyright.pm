=head1 LICENSE

Copyright [2009-2015] EMBL-European Bioinformatics Institute

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
      <li><a href="http://www.ebi.ac.uk"><img src="/img/ebi_logo.png" title="European Molecular Biology Laboratory - European Bioinformatics Institute" /></a></li>
      <li><a href="http://www.sanger.ac.uk"><img src="/img/sanger_logo.png" title="Wellcome Trust Sanger Institute" /></a></li>
      <li><a href="http://www.ensembl.org"><img src="/img/empowered.png" title="Powered by Ensembl" /></a></li>
      <li><a href="http://www.bbsrc.ac.uk"><img src="/img/bbsrc_logo.gif" title="Funded by BBSRC" /></a></li>
    </ul>
    WormBase ParaSite is funded by the <a href="http://www.bbsrc.ac.uk">UK Biotechnology and Biological Sciences Research Council</a> under grant numbers BB/K020080/1 and BB/K020048/1.
  </div>
  ), $sd->SITE_RELEASE_VERSION, $sd->SITE_RELEASE_DATE);
}

1;

