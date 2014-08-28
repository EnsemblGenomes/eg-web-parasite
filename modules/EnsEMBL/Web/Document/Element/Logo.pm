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

package EnsEMBL::Web::Document::Element::Logo;

use strict;

sub content {
  my $self   = shift;
  my $url    = $self->href || $self->home_url;
  my $hub    = $self->hub;
  my $type   = $hub->type;
  #my $e_logo = '<img src="/i/e.png" alt="WormBase ParaSite Home" title="WormBase ParaSite Home" class="print_hide" style="width:43px;height:40px" />'; 
  my $e_logo = ''; # Removed the small e! logo from ParaSite but kept variable so new logo could be inserted in future releases

  return sprintf( '%s<a href="%s">%s</a>%s',
    $self->e_logo, $url, $self->logo_print, $self->site_menu # Removes drop-down menu and e! logo
  );

}

sub logo_img {
### a
  my $self = shift;
  return 'WormBase ParaSite'; 
}

sub e_logo {
### a
  my $self = shift;
  my $alt = 'WormBase ParaSite Home';
  return sprintf(
    '<a href="%s"><img src="%s%s" alt="%s" title="%s" class="print_hide" style="height:%spx" /></a>',
    '/', $self->img_url, 'parasite.png', $alt, $alt, 34
  );
  return '';
}

sub site_menu {
  #return q{
  #  <span class="print_hide">
  #    <span id="site_menu_button">&#9660;</span>
  #    <ul id="site_menu" style="display:none">
  #      <li><a href="http://www.ensemblgenomes.org">WormBase ParaSite</a></li>
  #      <li><a href="http://bacteria.ensembl.org">Ensembl Bacteria</a></li>
  #      <li><a href="http://protists.ensembl.org">Ensembl Protists</a></li>
  #      <li><a href="http://fungi.ensembl.org">Ensembl Fungi</a></li>
  #      <li><a href="http://plants.ensembl.org">Ensembl Plants</a></li>
  #      <li><a href="http://metazoa.ensembl.org">Ensembl Metazoa</a></li>
  #      <li><a href="http://www.ensembl.org">Ensembl (vertebrates)</a></li>
  #    </ul>
  #  </span>
  #};
  return q{};
}

1;
