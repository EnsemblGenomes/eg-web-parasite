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

package EnsEMBL::Web::Component::Shared;

use strict;
use Bio::EnsEMBL::Gene;


sub species_stats {
  my $self = shift;
  my $sd = $self->hub->species_defs;
  my $html;
  my $db_adaptor = $self->hub->database('core');
  my $meta_container = $db_adaptor->get_MetaContainer();
  my $genome_container = $db_adaptor->get_GenomeContainer();
  my $html;

  my $cols = [
    { key => 'name', title => '', width => '30%', align => 'left' },
    { key => 'stat', title => '', width => '70%', align => 'left' },
  ];
  my $options = {'header' => 'no', 'rows' => ['bg3', 'bg1']};

  my $summary = $self->new_table($cols, [], $options);

  my( $a_id ) = ( @{$meta_container->list_value_by_key('assembly.name')},
                    @{$meta_container->list_value_by_key('assembly.default')});
  if ($a_id) {
    # look for long name and accession num
    if (my ($long) = @{$meta_container->list_value_by_key('assembly.long_name')}) {
      $a_id .= " ($long)";
    }
    if (my ($acc) = @{$meta_container->list_value_by_key('assembly.accession')}) {
      $acc = sprintf('<a href="http://www.ebi.ac.uk/ena/data/view/%s">%s</a>', $acc, $acc);
      $a_id .= ", $acc";
    }
  }
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Assembly</span>',
      'stat' => sprintf('%s%s', $a_id, $sd->ASSEMBLY_DATE ? ', '.$sd->ASSEMBLY_DATE : '')
  });
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Strain</span>',
      'stat' => $sd->SPECIES_STRAIN
  }) if $sd->SPECIES_STRAIN;
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Database Version</span>',
      'stat' => 'WBPS' . $sd->SITE_RELEASE_VERSION
  });
  my $header = $self->glossary_helptip('Genome Size', 'Golden path length');
  $summary->add_row({
      'name' => qq(<span style="font-weight: bold">$header</span>),
      'stat' => $self->thousandify($genome_container->get_ref_length())
  });
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Data Source</span>',
      'stat' => ref $sd->PROVIDER_NAME eq 'ARRAY' ? join(', ', @{$sd->PROVIDER_NAME}) : $sd->PROVIDER_NAME
  });
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Annotation Version</span>',
      'stat' => $sd->GENEBUILD_VERSION
  });

  $html .= $summary->render;

  ## GENE COUNTS
  $html .= $self->_add_gene_counts($genome_container,$sd,$cols,$options,'','');

  return $html;

}

1;
