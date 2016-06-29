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
    $html = qq{
      <script type="text/javascript">
        expressionAtlasHeatmapHighcharts.render ({
              gxaBaseUrl: "http://www.ebi.ac.uk/gxa/",
// ParaSite
              params:'geneQuery=$stable_id&species=$species&source=DEVELOPMENTAL_STAGE',
              isMultiExperiment: true,
              showAnatomogram: false,
              analyticsSearch: true,
//
              target : "expressionAtlas"
        });
      </script>  
      <div id="expressionAtlas"></div>    
    };
  }

  return $html;
}

1;
