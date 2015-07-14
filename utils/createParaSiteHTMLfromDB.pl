#!/usr/bin/perl

use strict;
use DBI;

my $outdir = "/nfs/public/rw/ensembl/websites/parasite/current/browser/eg-web-parasite/htdocs/ssi/species";

my @files_to_delete = <$outdir/about_*_*.html>;
unlink(@files_to_delete);

##############

my $dbh = DBI->connect("DBI:mysql:ensembl_production_parasite;host=mysql-eg-pan-prod:4276", 'ensro')
    || die "Could not connect to database: $DBI::errstr";

my $sql = "SELECT species_name, summary, assembly, annotation, resources, publication FROM static_genome";
my $sth = $dbh->prepare($sql);
$sth->execute();

my %keys = (1 => 'summary', 2 => 'assembly', 3 => 'annotation', 4 => 'resources', 5 => 'other');
my %labels = (1 => 'Summary', 2 => 'Assembly', 3 => 'Annotation', 4 => 'Resources', 5 => 'Key Publications');

while (my $result = $sth->fetchrow_arrayref) {
	my @results = @{$result};
	print "$results[0]\n";
	open(OUTFILE, ">$outdir/about_$results[0].html");
	for(my $i = 1; $i <= 5; $i++) {
		if($results[$i] ne '') {
			print OUTFILE qq(<!-- \{$keys{$i}\} --><a name="$keys{$i}"></a>\n);
			print OUTFILE qq(<h2>$labels{$i}</h2>\n);
			print OUTFILE qq(<p>$results[$i]</p>\n);
			print OUTFILE qq(<!-- \{$keys{$i}\} -->\n\n);
		}
	}
	close(OUTFILE);
}

##############

my $sql = "SELECT species_name, description FROM static_species";
my $sth = $dbh->prepare($sql);
$sth->execute();

my %keys = (1 => 'about');

while (my $result = $sth->fetchrow_arrayref) {
	my @results = @{$result};
	print "$results[0]\n";
	open(OUTFILE, ">/$outdir/about_$results[0].html");
	if($results[0] ne '') {
		print OUTFILE qq(<!-- \{$keys{1}\} --><a name="$keys{1}"></a>\n);
		print OUTFILE qq(<p>$results[1]</p>\n);
		print OUTFILE qq(<!-- \{$keys{1}\} -->\n\n);
	}
	close(OUTFILE);
}
