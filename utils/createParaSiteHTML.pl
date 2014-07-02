#!/usr/bin/perl

use strict;
use LWP::Simple;
use XML::Simple;
use HTML::Entities;
use Data::Dumper;

# Generate the static "about species x" and "about genome project x" pages for use in ParaSite

die "You should provide arguments: root directory, division name and input files. Ex: ./utils/createParaSiteHTML.pl /homes/bbolt/dev/parasite eg-web-parasite projects.txt species.txt"
        if (!$ARGV[0] || !$ARGV[1] || !$ARGV[2]  || !$ARGV[3]);

my ($root, $division, $projfile, $speciesfile) = @ARGV;

# Start by producing the genome project specific pages (about_Species_genus_bioproject.html)

open(INFILE, $projfile);

# Loop through each species
while(<INFILE>) {

	next if $. == 1;

	# Get the relevant bits of information from the species list
	chomp;
	my @parts = split('\t', $_);
	
	(my $species_lower = lc($parts[0])) =~ s/ /_/;
	(my $species_lower_space = $species_lower) =~ s/_/ /;
	my $species_cap = ucfirst($species_lower);
	my $species_cap_space = ucfirst($species_lower_space);
	
	my $bioproj = $parts[1];
	my $provider = $parts[6];
	my $assembly = 1;

	next if $bioproj eq '';
	
	$provider =~ s/The Genome Institute|WUGI/The Genome Institute at Washington University \(WUGI\)/;
	$provider =~ s/WTSI/The Wellcome Trust Sanger Institute \(WTSI\)/;

	my $db = lc("$species_lower\_$bioproj\_core_1_75_$assembly");
	my $filename = "about_$species_cap\_$bioproj.html";

	print "Project: $species_lower\_$bioproj; $filename\n";
	
	foreach(@parts) { # Strip the leading and ending delimiters
		$_ =~ s/"$//;
		$_ =~ s/"+//;
	}

	my @sections = (
		{
		   tagname    => "summary",
		   header     => "Summary",
		   paragraph  => $parts[2] eq '' ? "$provider assembly." : $parts[2],	# If there is a description in the input file use this, otherwise auto-generate something
		},
		{
		   tagname    => "assembly",
		   header     => "Assembly",
		   paragraph  => $parts[3] eq '' ? "$provider assembly." : $parts[3],	# If there is a description in the input file use this, otherwise auto-generate something
		},
		{
		   tagname    => "annotation",
		   header     => "Annotation",
		   paragraph  => $parts[4],
		},
		{
		   tagname    => "resources",
		   header     => "Resources",
		   paragraph  => $parts[7],
		},
		{
		   tagname    => "other",
		   header     => "Key Publications",
		   paragraph  => parse_references($parts[5]),	# If there is a PubMed ID(s) in the input file use this, otherwise auto-generate something
		},
	);

	# Print the HTML file
	my $outfile;
	foreach my $section (@sections) {
		next if $section->{paragraph} eq '' || $section->{paragraph} eq '<ul class="pub-list"></ul>';	# Ignore blanks
		$section->{paragraph} = parse_text($section->{paragraph});
		$outfile .= sprintf("<!-- {%s} --><a name=\"%s\"></a>\n<h2>%s</h2>\n<p>%s</p>\n<!-- {%s} -->\n\n", $section->{tagname}, $section->{tagname}, $section->{header}, $section->{paragraph}, $section->{tagname});
	}
	open(OUTFILE, ">$root/$division/htdocs/ssi/species/$filename");
	print OUTFILE $outfile;
	close(OUTFILE);

}

close(INFILE);

# Then create the species specific pages (about_Species_genus.html)

open(INFILE, $speciesfile);

# Loop through each species
foreach(<INFILE>) {

	# Get the relevant bits of information from the species list
	chomp;
	my @parts = split('\t', $_);
	
	(my $species_lower = lc($parts[0])) =~ s/ /_/;
	(my $species_lower_space = $species_lower) =~ s/_/ /;
	my $species_cap = ucfirst($species_lower);
	my $species_cap_space = ucfirst($species_lower_space);

	my $filename = "about_$species_cap.html";

	print "Species: $species_lower; $filename\n";
	
	foreach(@parts) { # Strip the leading and ending delimiters
		$_ =~ s/"$//;
		$_ =~ s/"+//;
	}

	my @sections = (
		{
		   tagname    => "about",
		   header     => "About <em>$species_cap_space</em>",
		   paragraph  => $parts[1],
		}
	);

	# Print the HTML file
	my $outfile;
	foreach my $section (@sections) {
		$section->{paragraph} = parse_text($section->{paragraph});
		$outfile .= sprintf("<!-- {%s} --><a name=\"%s\"></a>\n<h2>%s</h2>\n<p>%s</p>\n<!-- {%s} -->\n\n", $section->{tagname}, $section->{tagname}, $section->{header}, $section->{paragraph}, $section->{tagname});
	}
	open(OUTFILE, ">$root/$division/htdocs/ssi/species/$filename");
	print OUTFILE $outfile;
	close(OUTFILE);

}

close(INFILE);

sub parse_text {
	# Replace PMIDs and DOIs with the correct links
	my ($text) = @_;
	$text =~ s/\[PMID:(\d*)\]/<a href="http:\/\/europepmc\.org\/abstract\/MED\/$1">\[PMID:$1\]<\/a>/g;
	$text =~ s/doi: /doi:/g;
	$text =~ s/doi:(\S*)/<a href="http:\/\/dx.doi.org\/$1">doi:$1<\/a>/g;
	$text =~ s/(<em>.+) (.+<\/em>)/$1&nbsp;$2/g; # Make the space in the species names non-breaking
	return $text;
}

sub parse_references {
	# Convert a semi-colon separated list of PubMed IDs into a formatted list of references
	my ($pmid) = @_;
	my @items = split(';', $pmid);
	my $text = '<ul class="pub-list">';
	foreach my $item (@items) {
		$text .= '<li>' . get_reference($item) . '</li>';
	}
	$text .= '</ul>';
	return $text;
}

sub get_reference {
	# Form a reference from a PubMed ID
	my ($pmid) = @_;
	my $response = get("http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=$pmid");
	my $result = XMLin($response);
	my $text = encode_entities("$result->{resultList}->{result}->{authorString}  $result->{resultList}->{result}->{title}  ") . "<em>" . encode_entities($result->{resultList}->{result}->{journalTitle}) . "</em>" . encode_entities(", $result->{resultList}->{result}->{pubYear};$result->{resultList}->{result}->{journalVolume}($result->{resultList}->{result}->{issue}):$result->{resultList}->{result}->{pageInfo}.  doi:$result->{resultList}->{result}->{DOI} ");	# encode_entities will encode any symbolic characters (such as ligatures in author names) into the correct HTML
	return $text;
}
