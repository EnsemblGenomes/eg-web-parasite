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

package EnsEMBL::Web::Document::Element::ToolLinks;

use strict;

sub links {
  my $self  = shift;
  my $hub   = $self->hub;
  my $sd    = $self->species_defs;
  my @links;

  push @links, 'specieslist',   '<a class="constant" href="/species.html">Species List</a>';
  push @links, 'blast', sprintf '<a class="constant" href="%s">BLAST</a>', $self->hub->url({'species' => '', 'type' => 'Tools', 'action' => 'Blast'}) if $sd->ENSEMBL_BLAST_ENABLED;
  push @links, 'biomart',       '<a class="constant" href="/biomart/martview/">BioMart</a>';
  push @links, 'api',           '<a class="constant" href="/rest/">REST API</a>';
  push @links, 'downloads',     '<a class="constant" href="/ftp.html">Downloads</a>';
  push @links, 'wormbase',      '<a class="constant" href="http://www.wormbase.org">WormBase</a>';

  return \@links;
}

sub help_links {
  my $self = shift;
  my $hub  = $self->hub;
  my $users_available = $hub->users_available;
  my $user = $users_available ? $hub->user : undef;
  my @links;

  if($user && $users_available) {
    push @links, 'myaccount', sprintf('<a class="constant modal_link" href="%s">My Account - %s</a>', $hub->url({qw(type Account action Preferences)}), $user->email);
    push @links, 'logout', sprintf('<a class="constant" href="%s">Logout</a>', $hub->url({qw(type Account action Logout)}));
  } elsif($users_available) {
    push @links, 'login', sprintf('<a class="constant modal_link" href="%s">Login</a>', $hub->url({qw(type Account action Login)}));
    push @links, 'register', sprintf('<a class="constant modal_link" href="%s">Register</a>', $hub->url({qw(type Account action Register)}));
  }

  push @links, 'help', '<a class="constant" href="/info/">Help and Documentation</a>';

  return \@links;

}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $links   = $self->links;
  my $help_links = $self->help_links;
  my $menu    = '';
  my $html;

  while (my (undef, $link) =  splice @$links, 0, 2) {
    $menu .= sprintf '<li%s>%s</li>', @$links ? '' : ' class="last"', $link;
  }

  $html .= qq(<div class="tools-left"><ul class="tools">$menu</ul></div>);

  $menu = '';
  while (my (undef, $link) =  splice @$help_links, 0, 2) {
    $menu .= sprintf '<li%s>%s</li>', @$links ? '' : ' class="last"', $link;
  }

  $html .= qq(<div class="tools-right"><ul class="tools-right">$menu</ul></div>);

  return $html;
}

1;

