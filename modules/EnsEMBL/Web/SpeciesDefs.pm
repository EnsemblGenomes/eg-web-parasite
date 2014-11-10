package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;

sub _get_NCBIBLAST_source_file {
  my ($self, $species, $source_type) = @_;

  my $assembly = $self->get_config($species, 'ASSEMBLY_NAME');

  (my $type = lc $source_type) =~ s/_/\./;

  my $unit = $self->GENOMIC_UNIT;

  my $version = $self->ENSEMBL_VERSION;

  return sprintf 'wormbase-parasite/%s.%s.%s.%s', $species, $assembly, $version, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf 'wormbase-parasite/%s.%s.%s.%s', $species, $assembly, $version, $type;
}

1;
