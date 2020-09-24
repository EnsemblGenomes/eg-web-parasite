#!/usr/bin/perl
# Copyright [2014-2017] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Generate html files for web by converting markdown files from parasite-static repo

use strict;
use DBI;
use LWP::Simple;
use XML::Simple;
use HTML::Entities;
use FindBin;
use Text::MultiMarkdown qw(markdown);
use File::Slurp;

my %keys = (1 => 'summary', 2 => 'assembly', 3 => 'annotation', 4 => 'resources', 5 => 'publications');
my %labels = (1 => 'Summary', 2 => 'Assembly', 3 => 'Annotation', 4 => 'Resources', 5 => 'Key Publications');

my $outdir = "/nfs/public/release/ensweb/staging/parasite/server/browser/eg-web-parasite/htdocs/ssi/species";

my @files_to_delete = <$outdir/about_*_*.html>;
unlink(@files_to_delete);
my $PARASITE_STATIC_DIR = "$FindBin::RealBin/../../parasite-static/species";
eval qq{ require '$FindBin::RealBin/../conf/SiteDefs.pm' };     
EG::Web::ParaSite::SiteDefs::update_conf();
foreach my $name (@$SiteDefs::PRODUCTION_NAMES) {
  #print $name . "\n";
  my ($species, $bioproject) = $name =~ /^(\w+_\w+)_(\w+)$/;
  generate_html($species, $bioproject); 

}

sub generate_html {
  my ($species, $bioproject) = @_;
  my $Species = ucfirst $species;
  my $BIOPROJECT = uc $bioproject;
  my $outfile = "about_assembly_$Species\_$bioproject.html";
  print "Generating $outfile \n";
  open(OUTFILE, ">$outdir/$outfile");

  for(my $i = 1; $i <= 5; $i++) {
     my $md_file = "$PARASITE_STATIC_DIR/$Species/$BIOPROJECT/$Species\_$BIOPROJECT.$keys{$i}.md";
     if ($i == 5) {
        $md_file = "$PARASITE_STATIC_DIR/$Species/$BIOPROJECT/$Species\_$BIOPROJECT.publication.md";
     }
     #print $md_file . "\n";
     next unless (-e $md_file);
     my $markdown = File::Slurp::read_file($md_file);
     my $html;
     if ($i != 5) {
        $html = markdown($markdown);
     } else {
        my $comment = '[//]: #';
        my $pubids = $markdown =~ s/\Q$comment\E.*\n//gr; #Remove the comment line    
        $html = parse_references($pubids);
     } 
     
     print OUTFILE qq(<!-- \{$keys{$i}\} --><a name="$keys{$i}"></a>\n);
     print OUTFILE qq(<h2>$labels{$i}</h2>\n);
     print OUTFILE qq($html);
     print OUTFILE qq(<!-- \{$keys{$i}\} -->\n);
  }
  close(OUTFILE); 

# about_species file
  my $sp_outfile = "about_species_$Species.html";
  my $sp_md_file = "$PARASITE_STATIC_DIR/$Species/$Species.about.md";
  print "Generating $sp_outfile \n";
  open(OUTFILE, ">/$outdir/$sp_outfile");
  my $markdown = File::Slurp::read_file($sp_md_file);
  my $html = markdown($markdown);
  print OUTFILE qq(<!-- {about} --><a name="about"></a>\n);
  print OUTFILE qq($html);
  print OUTFILE qq(<!-- {about} -->\n);
  close(OUTFILE);

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
  my ($id) = @_;
  print "--Quering EuropePMC for $id\n";
  my $response = get("https://www.ebi.ac.uk/europepmc/webservices/rest/search/query=$id&pageSize=1");
  my $result = XMLin($response);
  my $pmid = $result->{resultList}->{result}->{pmid};
  my $text = encode_entities("$result->{resultList}->{result}->{authorString} ") . "<a href=\"http://europepmc.org/abstract/MED/$pmid\">" . encode_entities("$result->{resultList}->{result}->{title}") . "</a> <em>" . encode_entities($result->{resultList}->{result}->{journalTitle}) . "</em>" . encode_entities(", $result->{resultList}->{result}->{pubYear};$result->{resultList}->{result}->{journalVolume}($result->{resultList}->{result}->{issue}):$result->{resultList}->{result}->{pageInfo}");  # encode_entities will encode any symbolic characters (such as ligatures in author names) into the correct HTML
  return $text;
}

