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

package EnsEMBL::Web::File::AttachedFormat::BAM;

use LWP::UserAgent;
use Net::SSL;

use strict;

sub _check_cached_index {
  my ($self) = @_;
  my $index_url = $self->{url} . '.bai';
  my $tmp_file  = File::Spec->tmpdir . '/' . fileparse($index_url);
  if (-f $tmp_file) {
    my $local_time  = int stat($tmp_file)->[9];
## ParaSite: we need to use the proxy here
    my $proxy = $self->{'hub'}->species_defs->HTTP_PROXY;
    $ENV{HTTPS_PROXY} = $proxy;
    my $ua = LWP::UserAgent->new(
      ssl_opts => { verify_hostname => 0 },
      timeout => 2,
    );
    $ua->env_proxy;
    my $remote_time = int eval { $ua->head($index_url)->last_modified };
##
    if ($local_time <= $remote_time) {
      unlink $tmp_file;
    }
  }
}

1;

