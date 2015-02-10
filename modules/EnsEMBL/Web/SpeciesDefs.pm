package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;

sub _get_NCBIBLAST_source_file {
  my ($self, $species, $source_type) = @_;

  my $assembly = $self->get_config($species, 'ASSEMBLY_NAME');

  (my $type = lc $source_type) =~ s/_/\./;

  my $unit = $self->GENOMIC_UNIT;

  return sprintf 'wormbase-parasite/%s.%s.%s', $species, $assembly, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf 'wormbase-parasite/%s.%s.%s', $species, $assembly, $type;

}

1;
