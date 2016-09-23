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

sub species_label {
  my ($self, $key, $no_formatting) = @_;

  if( my $sdhash          = $self->SPECIES_DISPLAY_NAME) {
      (my $lcspecies = lc $key) =~ s/ /_/g;
      return $sdhash->{$lcspecies} if $sdhash->{$lcspecies};
  }

## ParaSite: use the SPECIES_COMMON_NAME instead of SPECIES_DISPLAY_NAME
  $key = ucfirst $key;
  my $scientific = $self->get_config($key, 'SPECIES_BIO_NAME');
  my $display    = $self->get_config($key, 'SPECIES_COMMON_NAME');
  my $bioproject = $self->get_config($key, 'SPECIES_BIOPROJECT');
  return $display ? $display : sprintf('<em>%s</em> (%s)', $scientific, $bioproject);

##

}

sub _get_NCBIBLAST_source_file {
  my ($self, $species, $source_type) = @_;

  my $assembly = $self->get_config($species, 'ASSEMBLY_NAME');

  (my $type = lc $source_type) =~ s/_/\./;

  my $unit = $self->GENOMIC_UNIT;
  my $path = $self->EBI_BLAST_DB_PREFIX || "wormbase-parasite";

  my $dataset = $self->get_config($species, 'SPECIES_DATASET');

  return sprintf '%s/%s.%s.%s', $path, $species, $assembly, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf '%s/%s.%s.%s', $path, $species, $assembly, $type;
}

1;
