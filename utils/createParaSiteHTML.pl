#!/usr/bin/perl

use strict;

# Generate the static "about species x" pages for use in ParaSite

die "You should provide arguments: root directory, division name and input file. Ex: ./utils/createParaSiteHTML.pl /homes/bbolt/dev/parasite eg-web-parasite blurbs.txt"
        if (!$ARGV[0] || !$ARGV[1] || !$ARGV[2]);

my ($root, $division, $infile) = @ARGV;

open(INFILE, $infile);

# Loop through each species
foreach(<INFILE>) {

	# Get the relevant bits of information from the species list
	chomp;
	my @parts = split('\t', $_);
	
	(my $species_lower = lc($parts[0])) =~ s/ /_/;
	(my $species_lower_space = $species_lower) =~ s/_/ /;
	my $species_cap = ucfirst($species_lower);
	my $species_cap_space = ucfirst($species_lower_space);
	
	my $bioproj = $parts[1];
	my $providername = $parts[7];
	my $assembly = 1;

	next if $bioproj eq '';

	my $db = lc("$species_lower\_$bioproj\_core_1_75_$assembly");
	my $filename = "about_$species_cap\_$bioproj.html";

	print "Species: $species_lower; $filename\n";
	
	foreach(@parts) { # Strip the leading and ending delimiters
		$_ =~ s/"$//;
		$_ =~ s/"+//;
	}

	my @sections = (
		{
		   tagname    => "about",
		   header     => "About <em>$species_cap_space</em>",
		   paragraph  => $parts[2],
		},
		{
		   tagname    => "annotation",
		   header     => "Annotation",
		   paragraph  => $parts[4],
		},
		{
		   tagname    => "assembly",
		   header     => "Assembly",
		   paragraph  => $parts[3],
		},
		{
		   tagname    => "resources",
		   header     => "Resources",
		   paragraph  => $parts[5],
		},
		{
		   tagname    => "other",
		   header     => "Key Publications",
		   paragraph  => $parts[6],
		},
	);

	# Print the HTML file
	my $outfile;
	foreach my $section (@sections) {
		next if $section->{paragraph} eq "-";	# Ignore blank key publications
		$section->{paragraph} =~ s/\[PMID:(\d*)\]/<a href="http:\/\/europepmc\.org\/abstract\/MED\/$1">\[PMID:$1\]<\/a>/g; # Replace PMIDs with a link to EuropePMC
		$section->{paragraph} =~ s/doi: /doi:/g;
		$section->{paragraph} =~ s/doi:(\S*)/<a href="http:\/\/dx.doi.org\/$1">doi:$1<\/a>/g; # Replace DOIs with a link
		$outfile .= sprintf("<!-- {%s} --><a name=\"%s\"></a>\n<h2>%s</h2>\n<p>%s</p>\n<!-- {%s} -->\n\n", $section->{tagname}, $section->{tagname}, $section->{header}, $section->{paragraph}, $section->{tagname});
	}
	open(OUTFILE, ">$root/$division/htdocs/ssi/species/$filename");
	print OUTFILE $outfile;
	close(OUTFILE);

}
