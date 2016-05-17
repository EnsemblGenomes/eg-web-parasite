package EnsEMBL::Web::ViewConfig::Karyotype;

use strict;
use POSIX qw/ceil/;

sub init {
  my $self = shift;

  $self->set_defaults({
    chr_length => 300,
    h_padding  => 4,
    h_spacing  => 6,
    v_spacing  => 10,
    rows       => ceil( scalar @{$self->species_defs->ENSEMBL_CHROMOSOMES} / 5 ), ## ParaSite: show a maximum of five chromosomes on each row
  });
}

1;

