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

package EnsEMBL::Web::Apache::Handlers;

use strict;

our $species_defs = EnsEMBL::Web::SpeciesDefs->new;

sub parse_ensembl_uri {
  ## Parses and saves uri components in subprocess_env if not already parsed
  ## @param Apache2::RequestRec request object
  ## @return undef if parsed successfully or a URL string if a redirect is needed after cleaning the species name
  my $r = shift;

  # return if already parsed
  return if $r->subprocess_env('ENSEMBL_PATH');

  my $parsed_uri  = $r->parsed_uri;
  my $uri_path    = $parsed_uri->path // '';
  my $uri_query   = $parsed_uri->query // '';
  
  # if there's nothing to parse, it's a homepage request - redirect to index.html in that case
  return join '?', '/index.html', $uri_query || () if $uri_path eq '/';

## ParaSite: redirect non-WormBase species out to wherever they belong, as defined in the configs
  my @uri_parts = split('/', $uri_path);
  my $sp = $uri_parts[1];
  my $site_type = $species_defs->ENSEMBL_SPECIES_SITE(lc($sp));
  if($site_type && $site_type !~ /^parasite|wormbase$/i) {
    my %param = split ';|=', $uri_query;
    my $redirect_url;
    if($uri_parts[2] eq 'Gene') {
      $redirect_url = $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($site_type) . "_GENE"};
      $redirect_url =~ s/###SPECIES###/$sp/;
      $redirect_url =~ s/###ID###/$param{'g'}/;
    } elsif ($uri_parts[2] eq 'Transcript') {
      $redirect_url = $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($site_type) . "_TRANSCRIPT"};
      $redirect_url =~ s/###SPECIES###/$sp/;
      $redirect_url =~ s/###ID###/$param{'t'}/;
    } elsif ($uri_parts[2] eq 'Info' || !$uri_parts[2]) {
      $redirect_url = $site_type eq 'WORMBASE' ? $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($sp) . "_URL"} : $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($site_type) . "_SPECIES"};
      $redirect_url =~ s/###SPECIES###/$sp/;
    }
    if($redirect_url) {
      return $redirect_url;
    }
  }
##

  my $species_alias_map = $species_defs->multi_val('ENSEMBL_SPECIES_URL_MAP') || {};
  my %valid_species_map = map { $_ => 1 } $species_defs->valid_species;

  # filter species alias map to remove any species that are not present in a list returned by $species_defs->valid_species
  $valid_species_map{$species_alias_map->{$_}} or delete $species_alias_map->{$_} for keys %$species_alias_map;

  # extract the species name from the raw path segments, and leave the remainders as our final path segments
  my ($species, $species_alias);
  my @path_segments = grep { $_ ne '' && ($species || !($species = $species_alias_map->{lc $_} and $species_alias = $_)) } split '/', $uri_path;

  # if species name provided in the url is not the formal species url name, it's time to redirect the request to the correct species url
  return '/'.join('?', join('/', $species, @path_segments), $uri_query eq '' ? () : $uri_query) if $species && $species ne $species_alias;

  $r->subprocess_env('ENSEMBL_SPECIES', $species) if $species;
  $r->subprocess_env('ENSEMBL_PATH',  '/'.join('/', @path_segments));
  $r->subprocess_env('ENSEMBL_QUERY', $uri_query);

  return undef;
}

1;
