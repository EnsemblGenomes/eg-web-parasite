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

sub species_autocomplete {
  my ($self, $hub) = @_;
  my $species_defs  = $hub->species_defs;
  my $term          = $hub->param('term'); # will return everything if no term specified
  my $result_format = $hub->param('result_format') || 'simple'; # simple/chosen
  
  my @species = $species_defs->valid_species;
  
  # sub to normalise strings for comparison e.g. k-12 == k12
  my $normalise = sub { 
    my $str = shift;
    $str =~ s/[^a-zA-Z0-9 ]//g;
    return $str;
  };
  
  $term = $normalise->($term);

  # find matches
  my @matches;
  foreach my $sp (@species) {
    my $name    = $species_defs->get_config($sp, "SPECIES_COMMON_NAME") || $species_defs->get_config($sp, "SPECIES_SCIENTIFIC_NAME");
## ParaSite: add alternative names into the autocomplete suggestions
    my $alt_names = $species_defs->get_config($sp, "SPECIES_ALTERNATIVE_NAME");
    my ($bioproj) = $name =~ /\((.*)\)/; # Capture the BioProject and append to the alternative names
    my @alt_proj  = map {qq/$_ \($bioproj\)/} @{$alt_names};
    my @names     = $alt_names ? ($name, @alt_proj) : ($name);
    my $url       = $species_defs->ENSEMBL_SPECIES_SITE->{lc($sp)} eq 'WORMBASE' ? $hub->get_ExtURL(uc($sp) . "_URL", {'SPECIES'=>$sp}) : "/$sp"; # Link back to WormBase if this is a non-parasitic species
    foreach my $search (@names) {
      next unless $search =~ /\Q$term\E/i;
      
      my $begins_with = $search =~ /^\Q$term\E/i;

      push(@matches, {
        value => "$search",
        production_name => $sp,
        url => $url,
        begins_with => $begins_with,
      });
    }
##
  }

  # sub to make alpha-numeric comparison but give precendence to 
  # strings that begin with the search term
  my $sort = sub {
    my ($a, $b) = @_;
    return $a->{value} cmp $b->{value} if $a->{begins_with} == $b->{begins_with};
    return $a->{begins_with} ? -1 : 1;
  };

  @matches = sort {$sort->($a, $b)} @matches;
  
  my $data;
  
  if ($result_format eq 'chosen') {
    # return results in format compatible with chosen.ajaxaddition.jquery.js
    $data = {
      q => $hub->param('term'), # original term
      results => \@matches
    };
  } else {
    # default to simple array format
    $data = [@matches];
  }

  print $self->jsonify($data);
}

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
  print encode_json(\@suggestions);
}

1;
