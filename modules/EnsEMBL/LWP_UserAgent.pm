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

package EnsEMBL::LWP_UserAgent;

use LWP;

sub user_agent {
  my $self = shift;

  my $species_defs = EnsEMBL::Web::SpeciesDefs->new;
  $ENV{HTTPS_PROXY} = $species_defs->HTTP_PROXY;
  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new(
      ssl_opts => { verify_hostname => 1 },
    );
    $ua->agent('WormBase ParaSite (EMBL-EBI) Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->proxy(['http', 'https'], $species_defs->HTTP_PROXY);
    $ua->timeout(2);
    $self->{user_agent} = $ua;
  }

  return $self->{user_agent};
}

1;
