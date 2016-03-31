package EnsEMBL::Web::VEPConstants;

use strict;
use warnings;

sub INPUT_FORMATS {
  return [
    { 'value' => 'vcf',     'caption' => 'VCF',                 'example' => qq(1  909238  var1  G  C  .  .  .\n3  361463  var2  GA  G  .  .  .\n5  121187650 sv1   .  &lt;DUP&gt;  .  .  SVTYPE=DUP;END=121188519  .) },
  ];
}

1;

