=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

# $Id: TextSequence.pm,v 1.8 2013-09-05 13:07:16 nl2 Exp $

package EnsEMBL::Web::Component::TextSequence;

use strict;

use previous qw(buttons);
 
sub buttons {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my @buttons      = $self->PREV::buttons(@_);
  pop @buttons; # Remove the enasearch button
  return @buttons;
}

1;
