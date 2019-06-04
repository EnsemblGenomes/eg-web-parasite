use strict;
use warnings;

# 
# Data for the taxonomy tree widget in WormBase ParaSite martview
# Connects to the EnsEMBL taxonomy database to obtain tree structure
# Connects to our (unmerged) mart to get biomart keys from dataset_names
# writes to STDOUT

use JSON qw/to_json/;
use Getopt::Long;
use DBI;

my $NO_CACHE = 1; # don't cache the registry
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::TaxonomyNodeAdaptor;

my ($host, $port, $user, $pass, $biomart_db_name);
GetOptions (
    "host=s"=>\$host,
    "port=i"=>\$port,
    "user=s"=>\$user,
    "pass=s"=>\$pass,
    "biomart_db=s"=> \$biomart_db_name,
);
for ($host, $port, $user, $biomart_db_name){
  unless ($_){
    die "Usage: $0 \$(\$PARASITE_STAGING_MYSQL details script) -biomart_db parasite_mart_\${PARASITE_VERSION} > tree.js";
  }
}

Bio::EnsEMBL::Registry->load_registry_from_db(-host => $host, -port => $port, -user => $user, -pass => $pass); 
Bio::EnsEMBL::Registry->set_disconnect_when_inactive;

my $biomart_db = DBI->connect("DBI:mysql:$biomart_db_name:$host:$port", $user, $pass);

my @dbas  = @{ Bio::EnsEMBL::Registry->get_all_DBAdaptors(-group => 'core') };

#------------------------------------------------------------------------------

my $node_adaptor = Bio::EnsEMBL::DBSQL::TaxonomyNodeAdaptor->new(Bio::EnsEMBL::Registry->get_all_DBAdaptors (-group => 'taxonomy')->[0]);

my $root_Nematoda = $node_adaptor->fetch_by_taxon_name("Nematoda");
my $root_Platyhelminthes = $node_adaptor->fetch_by_taxon_name("Platyhelminthes");
my $root_Other = $node_adaptor->fetch_by_taxon_name("Eukaryota");

my %leaf_nodes;
for my $dba (@dbas) {
  next if $biomart_db_name eq "parasite_mart_13" and ( $dba->species eq "micoletzkya_japonica_prjeb27334" or $dba->species eq "pristionchus_japonicus_prjeb27334"); # We had a boo-boo in WBPS13. delete this line in WBPS14!
  my $node = $node_adaptor->fetch_by_coredbadaptor($dba);
  my $category = $node->has_ancestor($root_Nematoda) ? "Nematoda" : $node->has_ancestor($root_Platyhelminthes) ? "Platyhelminthes" : "Other";
  push @{$leaf_nodes{$category}}, $node;
}

build_pruned_tree($node_adaptor, $root_Nematoda, $leaf_nodes{"Nematoda"});
$node_adaptor->collapse_tree($root_Nematoda);

build_pruned_tree($node_adaptor, $root_Platyhelminthes, $leaf_nodes{"Platyhelminthes"});
$node_adaptor->collapse_tree($root_Platyhelminthes);

$root_Other->{names}{"scientific name"} = [ sprintf("Other (%s)", scalar @{$leaf_nodes{"Other"}}) ];
$_->children([]) for @{$leaf_nodes{"Other"}};
$root_Other->children($leaf_nodes{"Other"});

my $sth = $biomart_db->prepare("select name, species_name from dataset_names where sql_name=?");
my $json = to_json(
  [ map {
      node_to_dynatree($_, $sth)
    } $root_Nematoda, $root_Platyhelminthes, $root_Other
  ],
  {pretty => 1, allow_nonref => 1}
);



print "taxonTreeData = $json;";

exit;

#------------------------------------------------------------------------------

# Faster version of Bio::EnsEMBL::DBSQL::TaxonomyNodeAdaptor::build_pruned_tree
sub build_pruned_tree {
  my ($node_adaptor, $root_requested, $leaf_nodes) = @_;
  my %leaf_ancestors;
  for my $leaf_node (@{$leaf_nodes}){
    for my $ancestor_node (@{$node_adaptor->fetch_ancestors($leaf_node)}){
      $leaf_ancestors{$ancestor_node->taxon_id} = $ancestor_node;
    }
  }
  return $node_adaptor->associate_nodes( [ $root_requested, grep {$_->has_ancestor($root_requested)} values %leaf_ancestors, @{$leaf_nodes}]);
}

sub node_to_dynatree {
  my ($node, $biomart_sth) = @_;
  my $name        = $node->names->{'scientific name'}->[0];
  my @child_nodes = @{$node->children};
  my @output;
  return {
    key      => $name,
    title    => $name,
    children => [ sort {$a->{title} cmp $b->{title}} map { node_to_dynatree($_, $biomart_sth) } @{$node->children} ],
    isFolder => \"1"
  } if @{$node->children};

  my ($dba, @others) = @{$node->dba};
  die unless $dba and not @others;
  $biomart_sth->execute($dba->species) || die "Could not retrieve name and display from biomart for ".$dba->species;
  my ($biomart, $display) = $biomart_sth->fetchrow_array;
  die "Could not retrieve name and display from biomart for ".$dba->species unless $biomart and $display;
  return {
    key   => $dba->species,
    title => $display,
    biomart => $biomart,
  };
}
