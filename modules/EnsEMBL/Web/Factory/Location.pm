package EnsEMBL::Web::Factory::Location;

use strict;

use previous qw(createObjects);

sub createObjects {
  my $self  = shift;
  my $hub = $self->hub;

## ParaSite: temporary hack to deal with S. mansoni seq region names
  my $params = {};
  foreach($self->param) {
warn $_;
    $params->{$_} = $hub->param($_);
  }
warn Data::Dumper::Dumper $params;
  unless($params->{'r'} =~ /^Smp\.Chr/) {
    $params->{'r'} = sprintf("Smp.Chr_%s", $params->{'r'});
warn Data::Dumper::Dumper $params;
warn "redirect";
    $self->problem('redirect', $hub->url($params));
  }
##

  $self->PREV::createObjects(@_);

}

1;

