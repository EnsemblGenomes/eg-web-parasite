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

package EnsEMBL::Web::Component::WormBaseLink;

use strict;

use base qw(EnsEMBL::Web::Component);
use Bio::EnsEMBL::Gene;

##########
#
#This module deals with external links to WormBase, for the species that are in both WB and WBPS
#
#########

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $species = $hub->species;
  my $html;

  # Link to JBrowse
  if($hub->param('r') && defined($hub->species_defs->ENSEMBL_EXTERNAL_URLS->{uc("$species\_JBROWSE")})) {
    (my $region = $hub->param('r')) =~ s/-/../;
    (my $highlight = $hub->param('mr')) =~ s/-/../;
    $html .= '<br />' if $html;
    $html .= $hub->get_ExtURL_link('[View region in WormBase JBrowse]', uc("$species\_JBROWSE"), {'SPECIES'=>$species, 'REGION'=>$region, 'HIGHLIGHT'=>$highlight});
    $html =~ s/<a /<a id="jbrowse-link" /;
  }

  # Link to the relevant gene page
  my $xrefs;
  my $gene;
  if(ref($self->object) =~ /::Gene\b/) {
    $gene = $self->object->Obj;
    $xrefs = $gene->get_all_DBEntries();
  } elsif(ref($self->object) =~ /::Transcript\b/) {
    $gene = $self->object->gene;
    $xrefs = $gene->get_all_DBEntries();
  }
  if($xrefs) {
    my $species = $hub->species;
    foreach my $xref (@{$xrefs}) {
      $html .= '<br />' if $html && $xref->dbname =~ /^wormbase_gene$/i;
      $html .= $hub->get_ExtURL_link('[View gene at WormBase central]', 'WORMBASE_GENE', {'SPECIES'=>$species, 'ID'=>$gene->stable_id}) if $xref->dbname =~ /^wormbase_gene$/i;
    }
  }

  return qq(<div class="wormbase_panel">$html</div>);
}

1;

