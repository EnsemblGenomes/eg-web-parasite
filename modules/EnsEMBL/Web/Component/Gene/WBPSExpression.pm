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

package EnsEMBL::Web::Component::Gene::WBPSExpression;

use strict;

use EnsEMBL::Web::Component::Gene::WBPSExpressionHelper;
use HTML::Entities qw(encode_entities);
use URI::Escape;
use base qw(EnsEMBL::Web::Component);
use Data::Dumper;

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $species     = lc($hub->species);
  my $stable_id   = $hub->param('g');
  my $url 	      = $hub->url;  
  
  my ($gene_category) = $url =~ m/WBPSExpression(.*)\?/g;
  $gene_category =~ s/_/ /g;

  my $html;
  $html = sprintf '<h3> Gene Expression %s of %s</h3>', $gene_category, $species;
  my $studies_path = "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/expression/$species/";
  my $wbps_exp = EnsEMBL::Web::Component::Gene::WBPSExpressionHelper->from_folder($species, $studies_path);
  $html .= $wbps_exp->render_page($stable_id, $gene_category);
  return $html;
}


1;
