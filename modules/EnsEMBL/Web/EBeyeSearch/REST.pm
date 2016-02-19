=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::EBeyeSearch::REST;

use strict;

my $debug = 0;

sub get {
  my ($self, $method, $args) = @_;
  $args ||= {};
  $args->{format} = 'json';

  my $uri = URI->new($self->base_url . ($method ? "/$method" : ''));
  $uri->query_param( $_, $args->{$_} ) for keys %$args;

  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  $debug && warn "GET " . $uri->as_string;

  my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;

  if ($response->is_error) {
## ParaSite: do not die if the search service is unreachable
    warn 'EBI search error: ' . $response->status_line;
    return;
## ParaSite
  }

  return from_json($content);
}

1;

