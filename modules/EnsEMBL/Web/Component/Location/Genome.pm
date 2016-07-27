package EnsEMBL::Web::Component::Location::Genome;

use strict;

sub buttons {
  my $self    = shift;
  my $hub     = $self->hub;
  my @buttons;

  my $params = {
                'type'    => 'UserData',
                'action'  => 'FeatureView',
                };

  return @buttons;
}

;
