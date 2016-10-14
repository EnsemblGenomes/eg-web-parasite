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

package EnsEMBL::Web::EBeyeSearch::WormBaseREST;

# Connects the WormBase search REST interface to the Ensembl genome browser

use strict;
use warnings;
use Data::Dumper;
use HTTP::Message;
use LWP;
use URI::QueryParam;
use JSON;

use base qw(EnsEMBL::Web::EBeyeSearch);

my $debug = 0;

sub new {
  my ($class, %args) = @_;
  my  $self = {
    base_url => 'http://www.wormbase.org/search/gene',
  };
  bless $self, $class;
  return $self;
}

sub base_url { $_[0]->{base_url} }

sub user_agent { 
  my $self = shift;
  
  my $hub = $self->hub;
  my $species_defs = $hub->species_defs;
  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new();
    $ua->agent('ParaSite Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->proxy(['http', 'https'], $species_defs->ENSEMBL_WWW_PROXY);
    $ua->timeout(5);
    $self->{user_agent} = $ua;
  }
  
  return $self->{user_agent};
}

sub get { 
  my ($self, $method, $args) = @_;
  my $query = $args->{'query'};
  my $page  = $args->{'page'} || 0;

  my $url   = $args->{'url'} ? $args->{'url'} : ($self->base_url . "/$query/$page?content-type=application/json");
  my $uri   = URI->new($url);
  
  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  $debug && warn "GET " . $uri->as_string;
  
  my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;
  
  if ($response->is_error) {
    warn 'WormBase search error: ' . $response->status_line;
    return;
  }

  $debug && warn "Response " . $content;
  if($args->{'plain'}) {
    return $content;
  } else {
    return from_json($content);
  }
}

sub get_results {
  my ($self, $domain, $query, $args) = @_;
  $args ||= {};

  return $self->get($domain, {%$args, query => $query});
}

sub get_results_count {
  my ($self, $domain, $query) = @_;
  my $results = $self->get($domain, {plain => 1, url => "http://www.wormbase.org/search/count//gene/$query"});
  $results =~ s/K$/000/; # Hack to deal with WormBase API returning values suffixed with K instead of an integer
  $results =~ s/\+$//g;
  if($results =~ /^[+-]?\d+$/) {
    return $results || 0;
  } else {
    return 0;
  }
}

sub get_results_as_hashes {
  my ($self, $domain, $query, $args) = @_;
  $args ||= {};
  my $results = $self->get($domain, {%$args, query => $query});

  my $hashes = [];
  foreach my $entry (@{$results->{results}}) {
    my %hash = ();
    # Map to the EG search keys
    $hash{'system_name'} = $entry->{taxonomy}->{genus} . '_' . $entry->{taxonomy}->{species};
    $hash{'species'}     = ucfirst($entry->{taxonomy}->{genus}) . ' ' . $entry->{taxonomy}->{species};
    $hash{'description'} = $entry->{concise_description}->[0];
    $hash{'label'}       = $entry->{name}->{label};
    $hash{'id'}          = $entry->{name}->{id};
    $hash{'name'}        = $hash{'label'} eq $hash{'id'} ? $hash{'label'} : ($hash{'label'} . ' [' . $hash{'id'} . ']');
    $hash{'species_path'}= "http://www.wormbase.org/species/" . $entry->{name}->{taxonomy};
    $hash{'url'}         = $hash{'species_path'} . "/gene/" . $hash{'id'};

    push @$hashes, \%hash;
  }
  return $hashes;
}

1;
