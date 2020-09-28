use strict;
use warnings;

# 
# Data for the taxonomy tree widget in WormBase ParaSite martview
# Connects to the EnsEMBL taxonomy database to obtain tree structure
# Connects to our (unmerged) mart to get biomart keys from dataset_names
# writes two files in plugin dir (default ../htdocs)
# Run from dev machine: perl -I ensembl-taxonomy/modules/ -I ensembl/modules/ eg-web-parasite/utils/taxon_trees.pl --host xxxx --port xxxx --user xxxx --biomart_db parasite_mart_13
#

our $BIOMART_TAXON_TREE_FILE_NAME = "martview_taxon_tree.js";
our $BLAST_TAXON_TREE_FILE_NAME = "taxon_tree_data.js";
use JSON qw/to_json/;
use Getopt::Long;
use DBI;
use File::Slurp qw/write_file/;
use FindBin;

my $NO_CACHE = 1; # don't cache the registry
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor;

my ($host, $port, $user, $pass, $plugin_dir, $biomart_db_name);
GetOptions (
    "host=s"=>\$host,
    "port=i"=>\$port,
    "user=s"=>\$user,
    "pass=s"=>\$pass,
    "plugin_dir=s" => \$plugin_dir,
    "biomart_db=s"=> \$biomart_db_name,
);
$plugin_dir //= "$FindBin::Bin/../htdocs";
print "Plugin Dir is $plugin_dir \n";

my $usage = "Usage: $0 \$(\$PARASITE_STAGING_MYSQL details script) -biomart_db parasite_mart_\${PARASITE_VERSION} [--plugin_dir . ]";
die $usage unless -d $plugin_dir;
for ($host, $port, $user, $biomart_db_name){
  die $usage unless $_;
}

Bio::EnsEMBL::Registry->load_registry_from_db(-host => $host, -port => $port, -user => $user, -pass => $pass); 
Bio::EnsEMBL::Registry->set_disconnect_when_inactive;

my $biomart_db = DBI->connect("DBI:mysql:$biomart_db_name:$host:$port", $user, $pass);

my @dbas  = @{ Bio::EnsEMBL::Registry->get_all_DBAdaptors(-group => 'core') };

#------------------------------------------------------------------------------

my $node_adaptor = Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor->new(Bio::EnsEMBL::Registry->get_all_DBAdaptors (-group => 'taxonomy')->[0]);

my $root_Nematoda = $node_adaptor->fetch_by_taxon_name("Nematoda");
my $root_Platyhelminthes = $node_adaptor->fetch_by_taxon_name("Platyhelminthes");
my $root_Other = $node_adaptor->fetch_by_taxon_name("Eukaryota");

my %leaf_nodes;
for my $dba (@dbas) {
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
my $json_biomart = to_json(
  [ 
    node_to_dynatree($root_Nematoda, $sth),
    node_to_dynatree($root_Platyhelminthes, $sth),
    node_to_dynatree($root_Other, $sth),
  ],
  {pretty => 1, allow_nonref => 1}
);

my $json_blast = to_json(
  [ 
    node_to_dynatree($root_Nematoda, ""),
    node_to_dynatree($root_Platyhelminthes, ""),
  ],
  {pretty => 1, allow_nonref => 1}
);

print "Writing $BIOMART_TAXON_TREE_FILE_NAME \n";
write_file (join("/", $plugin_dir, $BIOMART_TAXON_TREE_FILE_NAME), "taxonTreeData = $json_biomart;");
print "Writing $BLAST_TAXON_TREE_FILE_NAME \n";
write_file (join("/", $plugin_dir, $BLAST_TAXON_TREE_FILE_NAME), "taxonTreeData = $json_blast;");

exit;

#------------------------------------------------------------------------------


# Faster version of Bio::EnsEMBL::DBSQL::TaxonomyNodeAdaptor::build_pruned_tree
# It's theoretically worse - one query per leaf, instead of one big query - but much faster for us
sub build_pruned_tree {
  my ($self, $root, $leaf_nodes) = @_;

  my @leaf_nodes_under_root = grep {$_->has_ancestor($root)} @{$leaf_nodes};
  my %leaf_node_taxons = map {$_->taxon_id => $_} @leaf_nodes_under_root;
  my %ancestor_nodes;
  for my $leaf_node (@leaf_nodes_under_root){
    for my $ancestor_node (@{$self->fetch_ancestors($leaf_node)}){
      if ($ancestor_node->has_ancestor($root) and not $leaf_node_taxons{$ancestor_node->taxon_id}){
        $ancestor_nodes{$ancestor_node->taxon_id} = $ancestor_node;
      }
    }
  }
  return $self->associate_nodes( [ $root, values %ancestor_nodes, @leaf_nodes_under_root]);
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

  for my $dba (@{$node->dba}) {
    if ($biomart_sth){
      $biomart_sth->execute($dba->species) || die "Could not retrieve name and display from biomart for ".$dba->species;
      my ($biomart, $display) = $biomart_sth->fetchrow_array;
      die "Could not retrieve name and display from biomart for ".$dba->species unless $biomart and $display;
      return {
        key   => $dba->species,
        title => $display,
        biomart => $biomart,
      };
    } else {
      my @parts = split "_", $dba->species;
      my $bioproject = uc($parts[2]//"");
      my $display = $bioproject ? "$name ($bioproject)" : $name;
      return {
         key =>$dba->species,
         title => $display,
      };
    }
  }
}
