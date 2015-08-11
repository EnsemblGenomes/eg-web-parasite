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

package EnsEMBL::Web::Controller::Ajax;

use strict;
use LWP;
use URI::QueryParam;
use JSON;

sub search_autocomplete {
  my ($self, $hub) = @_;
  my $species_defs  = $hub->species_defs;
  my $term          = $hub->param('term');
  my $format        = $hub->param('format');
  my $ua = LWP::UserAgent->new();
     $ua->agent('EnsemblGenomes Web ' . $ua->agent());
     $ua->env_proxy;
     $ua->timeout(10);
my $uri = URI->new($species_defs->EBEYE_REST_ENDPOINT . "/" . $species_defs->EBEYE_SEARCH_DOMAIN . "/autocomplete");
     $uri->query_param('term'   => $term);
     $uri->query_param('format' => $format);
  my $response = $ua->get($uri->as_string);
  if ($response->is_error) {
    die;
  }
  my $results = from_json($response->content);
  my @suggestions = map($_->{'suggestion'}, @{$results->{suggestions}});

  my @matches;

## Has the user entered the name of a tool?
  push(@matches, { value=>'FTP Downloads', url=>'/ftp.html', type=>'WormBase ParaSite Tools' }) if $term =~ /ftp|download/i;
  push(@matches, { value=>'BLAST Sequence Search', url=>'/Tools/Blast?db=core', type=>'WormBase ParaSite Tools' }) if $term =~ /blast/i;
  push(@matches, { value=>'REST API', url=>'/api', type=>'WormBase ParaSite Tools' }) if $term =~ /rest|api/i;
  push(@matches, { value=>'WormBase ParaSite BioMart', url=>'/biomart/martview', type=>'WormBase ParaSite Tools' }) if $term =~ /biomart|mart|wormmine|wormmart|intermine/;
  push(@matches, { value=>'WormMine', url=>'http://www.wormbase.org/tools/wormmine', type=>'WormBase Tools' }) if $term =~ /wormmine|wormmart|intermine/;
  push(@matches, { value=>'WormBase Central', url=>'http://www.wormbase.org', type=>'WormBase Tools' }) if $term =~ /wormbase|legacy/i;
  push(@matches, { value=>'Full Species List', url=>'/species.html', type=>'WormBase ParaSite Tools' }) if $term =~ /species/i;
##

## Does the search term match a species name?
  my @species = $species_defs->valid_species;  
  my ($sp_term, $sp_genus) = $term =~ /^([A-Za-z])[\.]? ([A-Za-z]+)/ ? ($2, $1) : ($term, undef); # Deal with abbreviation of the genus
  foreach my $sp (@species) {
    my $name    = $species_defs->get_config($sp, "SPECIES_COMMON_NAME") || $species_defs->get_config($sp, "SPECIES_SCIENTIFIC_NAME");
    my $alt_names = $species_defs->get_config($sp, "SPECIES_ALTERNATIVE_NAME");
    my ($bioproj) = $name =~ /\((.*)\)/; # Capture the BioProject and append to the alternative names
    my @alt_proj  = map {qq/$_ \($bioproj\)/} @{$alt_names};
    my @names     = $alt_names ? ($name, @alt_proj) : ($name);
    my $url       = $species_defs->ENSEMBL_SPECIES_SITE->{lc($sp)} eq 'WORMBASE' ? $hub->get_ExtURL(uc($sp) . "_URL", {'SPECIES'=>$sp}) : "/$sp"; # Link back to WormBase if this is a non-parasitic species
    foreach my $search (@names) {
      next unless $search =~ /\Q$sp_term\E/i;
      next if $sp_genus && ($search !~ /^$sp_genus/i || $search !~ /^(.*?) .*$sp_term.*/i);
      my $begins_with = $search =~ /^\Q$sp_term\E/i;
      push(@matches, {
        value => "$search",
        url => $url,
        type => 'Species',
        begins_with => $begins_with
      });
    }
  }
  my $sort = sub {
    my ($a, $b) = @_;
    return $a->{value} cmp $b->{value} if $a->{begins_with} == $b->{begins_with};
    return $a->{begins_with} ? -1 : 1;
  };
  @matches = sort {$sort->($a, $b)} @matches;
  unshift(@suggestions, @matches);
##

  print encode_json(\@suggestions);
}

1;
