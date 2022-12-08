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

package EnsEMBL::Web::Document::Element::Logo;

use strict;

sub content {
  my $self   = shift;
  my $url    = $self->href || $self->home_url;
  my $hub    = $self->hub;
  my $type   = $hub->type;
  my $alt = 'WormBase ParaSite Home';
  my $wbps_release = $hub->species_defs->SITE_RELEASE_VERSION;
  my $wb_release = $hub->species_defs->WORMBASE_RELEASE_VERSION;
  my $version = sprintf("WBPS%s (WS%s)", $wbps_release, $wb_release);
  my $archive = sprintf("WBPS%s", $wbps_release - 1);

  return sprintf( '<a href="%s"><img src="%s%s" alt="%s" title="%s" style="height:%spx" /></a><span class="header-version">Version:&nbsp;<a href="/info/about/release-log.html">%s</a></span><span class="header-version">-&nbsp;&nbsp;Archive:&nbsp;<a href="https://release-%s.parasite.wormbase.org">%s</a></span>',
    '/', $self->img_url, 'parasite.png', $alt, $alt, 34, $version, $wbps_release - 1, $archive
  );

}

1;

