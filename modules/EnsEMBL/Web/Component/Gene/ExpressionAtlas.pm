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

package EnsEMBL::Web::Component::Gene::ExpressionAtlas;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;

sub content {
  my $self        = shift;

  my $hub         = $self->hub;
  my $object      = $self->object;
  my $stable_id   = $hub->param('g');
## ParaSite: can't use the species name as it contains the BioProject 
  my $species     = $hub->species_defs->SPECIES_SCIENTIFIC_NAME;
##
  my $html;

  $species        =~ s/_/ /gi; #GXA require the species with no underscore.  
  if (!$hub->gxa_status) {
    $html = $self->_info_panel("error", "Gene expression atlas site down!", "<p>The widget cannot be displayed as the gene expression atlas site is down. Please check again later.</p>");
  } else {
    #this script tag has been kept here as it was easier to call the perl param within the script tag (the js file wasn't getting the param)
## ParaSite
    (my $gxa_url = $SiteDefs::GXA_EBI_URL) =~ s/\/gxa\/$//;
    $html = sprintf(qq{
      <script language="JavaScript" type="text/javascript" src="%s/resources/js-bundles/vendorCommons.bundle.js"></script>
      <script language="JavaScript" type="text/javascript" src="%s/resources/js-bundles/expressionAtlasHeatmapHighcharts.bundle.js"></script>
      <script type="text/javascript">
        expressionAtlasHeatmapHighcharts.render ({
              atlasHost: "%s",
              params:'geneQuery=%s&species=%s&source=DEVELOPMENTAL_STAGE',
              isMultiExperiment: true,
              showAnatomogram: false,
              analyticsSearch: true,
              target : "expressionAtlas"
        });
      </script>  
      <div id="expressionAtlas"></div>    
    }, $SiteDefs::GXA_EBI_URL, $SiteDefs::GXA_EBI_URL, $gxa_url, $stable_id, $species);
##
  }
  return $html;
}

1;
