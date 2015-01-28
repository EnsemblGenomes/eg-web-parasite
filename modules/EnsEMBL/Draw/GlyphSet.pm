=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet;

use strict;
use Data::Dumper;

sub _url {
  my $self = shift;
  my $url = $self->{'config'}->hub->url('ZMenu', { %{$_[0]}, config => $self->{'config'}{'type'}, track => $self->type });;
  if($_[0]->{'species'}) {
    my $division = $self->{'config'}->hub->species_defs->ENSEMBL_SPECIES_SITE->{lc($_[0]->{'species'})};
    if($division =~ /WORMBASE/) {
      my $stable_id = $_[0]->{'g'};
      $url = $self->{'config'}->hub->get_ExtURL("$division\_GENE", $stable_id);
    }
  }
  return $url;
}

1;
