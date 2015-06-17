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
