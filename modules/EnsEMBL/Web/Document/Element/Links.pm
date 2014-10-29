package EnsEMBL::Web::Document::Element::Links;

sub init {
  my $self = shift;
  my $controller   = shift;
  my $hub          = $controller->hub;
  my $species      = $hub->species;
  my $species_defs = $self->species_defs;

  $self->add_link({
    rel  => 'icon',
    type => 'image/png',
    href => $species_defs->img_url . $species_defs->ENSEMBL_STYLE->{'SITE_ICON'}
  });

  $self->add_link({
    rel   => 'search',
    type  => 'application/opensearchdescription+xml',
    href  => '/opensearch.xml',
    title => 'WormBase ParaSite'
  });
  
}

1;
