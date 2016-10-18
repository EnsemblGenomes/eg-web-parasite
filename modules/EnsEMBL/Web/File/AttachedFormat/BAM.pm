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
    my $proxy = $self->{'hub'}->species_defs->ENSEMBL_WWW_PROXY;
    $ENV{HTTPS_PROXY} = $proxy;
    my $ua = LWP::UserAgent->new(
      ssl_opts => { verify_hostname => 0 },
      timeout => 2,
    );
    $ua->env_proxy;
    my $remote_time = int eval { $ua->head($index_url)->last_modified };
##
    if ($local_time <= $remote_time) {
      warn "Cached BAM index is older than remote - deleting $tmp_file";
      unlink $tmp_file;
    }
  }
}

1;

