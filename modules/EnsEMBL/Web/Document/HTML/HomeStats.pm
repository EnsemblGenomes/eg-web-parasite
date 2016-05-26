package EnsEMBL::Web::Document::HTML::HomeStats;

use strict;
use warnings;
use EnsEMBL::Web::RegObj;
use List::MoreUtils qw(uniq);
use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my ($class, $request) = @_;
  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  
  my @items;

  my @species_list = $species_defs->valid_species;
  my @scientific = uniq map { $species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME') } @species_list;

  push(@items, sprintf('Version: WBPS%s (%s)', $species_defs->SITE_RELEASE_VERSION, $species_defs->SITE_RELEASE_DATE));
  push(@items, sprintf('WormBase Version: WS%s', $species_defs->WORMBASE_RELEASE_VERSION));
  push(@items, sprintf('%s genomes, representing %s species', scalar(@species_list), scalar(@scientific)));
  
  return join("\n", map { "<li>$_</li>" } @items);

}

1;

