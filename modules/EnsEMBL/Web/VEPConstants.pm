=head1 LICENSE

Copyright [2014-2017] EMBL-European Bioinformatics Institute

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

