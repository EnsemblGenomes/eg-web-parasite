use strict;
use warnings;

# 
# Data for the taxonomy tree widget in WormBase ParaSite martview
# Connects to the EnsEMBL taxonomy database to obtain tree structure
# writes to STDOUT
#
use JSON qw/to_json/;
use Getopt::Long;

my $NO_CACHE = 1; # don't cache the registry
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor;

my ($host, $port, $user, $pass);
GetOptions (
    "host=s"=>\$host,
    "port=i"=>\$port,
    "user=s"=>\$user,
    "pass=s"=>\$pass,
);
for ($host, $port, $user){
  unless ($_){
    die "Usage: $0 \$(\$PARASITE_STAGING_MYSQL details script) > tree.js";
  }
}

Bio::EnsEMBL::Registry->load_registry_from_db(-host => $host, -port => $port, -user => $user, -pass => $pass); 
Bio::EnsEMBL::Registry->set_disconnect_when_inactive;

my @dbas  = grep {  
  3 == scalar split "_", $_->species
} @{ Bio::EnsEMBL::Registry->get_all_DBAdaptors(-group => 'core') };

#------------------------------------------------------------------------------

my $node_adaptor = Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor->new(Bio::EnsEMBL::Registry->get_all_DBAdaptors (-group => 'taxonomy')->[0]);

my $root_Nematoda = $node_adaptor->fetch_by_taxon_name("Nematoda");
my $root_Platyhelminthes = $node_adaptor->fetch_by_taxon_name("Platyhelminthes");

my %leaf_nodes;
for my $dba (@dbas) {
  my $node = $node_adaptor->fetch_by_coredbadaptor($dba);
  my $category = $node->has_ancestor($root_Nematoda) ? "Nematoda" : $node->has_ancestor($root_Platyhelminthes) ? "Platyhelminthes" : die $dba->species;
  push @{$leaf_nodes{$category}}, $node;
}

build_pruned_tree($node_adaptor, $root_Nematoda, $leaf_nodes{"Nematoda"});
$node_adaptor->collapse_tree($root_Nematoda);

build_pruned_tree($node_adaptor, $root_Platyhelminthes, $leaf_nodes{"Platyhelminthes"});
$node_adaptor->collapse_tree($root_Platyhelminthes);

my $json = to_json(
  [ 
    node_to_dynatree($root_Nematoda),
    node_to_dynatree($root_Platyhelminthes),
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
  my ($node) = @_;
  my $name        = $node->names->{'scientific name'}->[0];
  my @child_nodes = @{$node->children};
  my @output;
  return {
    key      => $name,
    title    => $name,
    children => [ sort {$a->{title} cmp $b->{title}} map { node_to_dynatree($_) } @{$node->children} ],
    isFolder => \"1"
  } if @{$node->children};

  my ($dba, @others) = @{$node->dba};
  die unless $dba and not @others;
  my @parts = split("_", $dba->species);
  my $bioproject = uc($parts[2]);
  die $dba->species unless $bioproject;
  return {
    key   => $dba->species,
    title => "$name ($bioproject)",
  };
}
