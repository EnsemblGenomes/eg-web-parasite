package EnsEMBL::LWP_UserAgent;

use LWP;

sub user_agent {
  my $self = shift;

  my $species_defs = EnsEMBL::Web::SpeciesDefs->new;
  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new();
    $ua->agent('WormBase ParaSite (EMBL-EBI) Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->proxy(['http', 'https'], $species_defs->ENSEMBL_WWW_PROXY);
    $ua->timeout(2);
    $self->{user_agent} = $ua;
  }

  return $self->{user_agent};
}

1;
