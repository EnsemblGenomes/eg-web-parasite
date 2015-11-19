package EnsEMBL::Web::Component::WormBaseLink;

use strict;

use base qw(EnsEMBL::Web::Component);
use Bio::EnsEMBL::Gene;
use JSON;

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

### TODO: Work on the bit below - this gets the user configured tracks and needs to append these onto the JBrowse URL
my $image_config = $hub->get_imageconfig('contigviewbottom');
my @tracks = $image_config->get_tracks;
my @jbrowse_tracks;
foreach my $row_config (@tracks) {
  next if $row_config->get('matrix') eq 'column';
  my $display = $row_config->get('display') || ($row_config->get('on') eq 'on' ? 'normal' : 'off');
  next if $display eq 'off' || $display =~ /highlight/;
  my $option_key = $row_config->get('option_key');
  next if $option_key && $image_config->get_node($option_key)->get('display') ne 'on';
  next unless $row_config->get('external') eq 'external';
  my %track = (
    'label' => $row_config->get('caption'),
    'store' => 'url',
    'storeClass' => 'JBrowse/Store/SeqFeature/BAM',
    'urlTemplate' => $row_config->get('url')
  );
  push @jbrowse_tracks, %track;
}
my $jbrowse_json = to_json(\@jbrowse_tracks);
print $jbrowse_json;

###TODO

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

