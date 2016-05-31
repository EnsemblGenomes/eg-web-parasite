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

package EnsEMBL::Web::SpeciesDefs;

use strict;


sub assembly_lookup {
  my ($self, $old_assemblies) = @_;
  my $lookup = {};
  foreach ($self->valid_species) {
    my $assembly = $self->get_config($_, 'ASSEMBLY_VERSION');
    ## A bit clunky, but it makes code cleaner in use
    $lookup->{$assembly} = [$_, $assembly, 0];
    if ($self->get_config($_, 'TRACKHUB_ASSEMBLY_ALIASES')) {
      my @aliases = @{$self->get_config($_, 'TRACKHUB_ASSEMBLY_ALIASES')};
      foreach my $alias (@aliases) {
        $lookup->{$alias} = [$_, $assembly, 0];
      }
    }
    ## Now look up UCSC assembly names
    if ($self->get_config($_, 'UCSC_GOLDEN_PATH')) {
      $lookup->{$self->get_config($_, 'UCSC_GOLDEN_PATH')} = [$_, $assembly, 0];
    }
    if ($old_assemblies) {
      ## Include past UCSC assemblies
      if ($self->get_config($_, 'UCSC_ASSEMBLIES')) {
        my %ucsc = @{$self->get_config($_, 'UCSC_ASSEMBLIES')||[]};
        while (my($k, $v) = each(%ucsc)) {
          $lookup->{$k} = [$_, $v, 1];
        }
      }
    }
  }
  return $lookup;
}

1;
