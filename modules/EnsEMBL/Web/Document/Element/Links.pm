=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Links;

sub init {
  my $self = shift;
  my $controller   = shift;
  my $hub          = $controller->hub;
  my $species      = $hub->species;
  my $species_defs = $self->species_defs;

  $self->add_link({
    rel  => 'icon',
    type => 'image/png',
    href => $species_defs->img_url . $species_defs->ENSEMBL_STYLE->{'SITE_ICON'}
  });

  $self->add_link({
    rel   => 'search',
    type  => 'application/opensearchdescription+xml',
    href  => '/opensearch.xml',
    title => 'WormBase ParaSite'
  });

  $self->add_link({
    rel   => 'alternate',
    type  => 'application/rss+xml',
    href  => 'https://wbparasite.wordpress.com/feed/',
    title => 'WormBase ParaSite Blog & Announcements'
  });
  
}

1;
