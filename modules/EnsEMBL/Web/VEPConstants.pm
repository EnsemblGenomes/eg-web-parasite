package EnsEMBL::Web::VEPConstants;

use strict;
use warnings;

sub INPUT_FORMATS {
  return [
    { 'value' => 'vcf',     'caption' => 'VCF',                 'example' => qq(1  909238  var1  G  C  .  .  .\n3  361463  var2  GA  G  .  .  .\n5  121187650 sv1   .  &lt;DUP&gt;  .  .  SVTYPE=DUP;END=121188519  .) },
  ];
}

sub CONFIG_SECTIONS {
  return [{
    'id'        => 'identifiers',
    'title'     => 'Identifiers and frequency data',
    'caption'   => 'Additional identifiers for genes, transcripts and variants; frequency data'
  }, {
    'id'        => 'extra',
    'title'     => 'Extra options',
    'caption'   => 'e.g. transcript biotype and protein domains'
  }, {
    'id'        => 'filters',
    'title'     => 'Filtering options',
    'caption'   => 'Pre-filter results by frequency or consequence type'
  # }, {
  #  'id'        => 'plugins',
  #  'title'     => 'Plugins',
  #  'caption'   => 'Extra functionality from VEP plugins'
  }];
}

1;

