package EnsEMBL::Web::Component::Gene::Go;
use strict;

sub biomart_link {
  my ($self, $term) = @_;

  #return '' unless $self->hub->species_defs->ENSEMBL_MART_ENABLED;

  my $vschema        = sprintf '%s_mart_%s', $self->hub->species_defs->GENOMIC_UNIT, $SiteDefs::SITE_RELEASE_VERSION;
## ParaSite: all our species have the same prefix in BioMart
  my $attr_prefix    = 'wbps_eg_gene';
##
  my ($ontology)     = split /:/, $term;
  my $biomart_filter = EnsEMBL::Web::Constants::ONTOLOGY_SETTINGS->{$ontology}->{biomart_filter};

  my $url  = sprintf(
    qq{/biomart/martview?VIRTUALSCHEMANAME=%s&ATTRIBUTES=%s.default.feature_page.ensembl_gene_id|%s.default.feature_page.ensembl_transcript_id&FILTERS=%s.default.filters.%s.%s&VISIBLEPANEL=resultspanel},
    $vschema,
    $attr_prefix,
    $attr_prefix,
    $attr_prefix,
    $biomart_filter,
    $term
  );

  my $link = qq{<a rel="notexternal" href="$url">Search Biomart</a>};

  return $link;
}

1;

