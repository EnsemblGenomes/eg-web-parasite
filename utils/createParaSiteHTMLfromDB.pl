#!/usr/bin/perl
# Copyright [2009-2016] EMBL-European Bioinformatics Institute
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


use strict;
use DBI;
use LWP::Simple;
use XML::Simple;
use HTML::Entities;

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
      $results[$i] = parse_references($results[$i]) if $i ==5;
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
  print "--Quering EuropePMC for $pmid\n";
  my $response = get("http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=$pmid");
  my $result = XMLin($response);
  my $text = encode_entities("$result->{resultList}->{result}->{authorString} ") . "<a href=\"http://europepmc.org/abstract/MED/$pmid\">" . encode_entities("$result->{resultList}->{result}->{title}") . "</a> <em>" . encode_entities($result->{resultList}->{result}->{journalTitle}) . "</em>" . encode_entities(", $result->{resultList}->{result}->{pubYear};$result->{resultList}->{result}->{journalVolume}($result->{resultList}->{result}->{issue}):$result->{resultList}->{result}->{pageInfo}");  # encode_entities will encode any symbolic characters (such as ligatures in author names) into the correct HTML
  return $text;
}

