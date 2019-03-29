use strict;
use warnings;
use Data::Dumper;

use Text::CSV qw/csv/;
use List::MoreUtils qw/uniq/;

## Read the htdocs/expression path and write categories to species' ini file.
#  It should be fine to run this script multiple times
##
  
## Path to expression files fetched from ftp
my $path = "/homes/ens_adm14/parasite/current/browser/eg-web-parasite/htdocs/expression";

## To mirror ftp, can do:
#  wget -P $path -nH --cut-dirs=8 -m ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite/web_data/rnaseq_studies/releases/next/

my @dirs = `ls $path`;

foreach my $species (@dirs) {
   chomp $species;
   my ($spe, $cies, $bp) = split "_", $species;
   my $tsv_path = "$path/$species/$spe\_$cies.studies.tsv"; 
   
   if (not -e $tsv_path) {
     print "IGNORED. No tsv file for $species\n";
     next;  
   }
   
   if (-z $tsv_path) {
     print "IGNORED. EMPTY tsv file for $species\n";
     next;
   }
   
   my @lines= @{csv(in=>$tsv_path, sep_char => "\t")};
   
   ## Finding categories and sort them.
   my @categories;
   for my $line (@lines) {
     my @line = @{$line};
     push @categories, $line[1];
   }
   my @categories_uniq = map { $_ =~ s/ /_/g; $_;} uniq(@categories);
   @categories_uniq = sort map { $_ =~ s/Other/ZZOther/g; $_;} @categories_uniq; 
   @categories_uniq = map { $_ =~ s/ZZOther/Other/g; $_;} @categories_uniq;  
   my $gene_cats = sprintf("EXP_CATEGORIES = [%s]" ,join " ", @categories_uniq);
   
   ## Grep the matching line
   my $ini_file = "$path/../../conf/ini-files/$species.ini"; 
   if (not -e $ini_file) {
     print "MISSING. tsv file exists BUT no ini file found for $species\n";
     next;
   }  

   my $found = `grep -n  '\\[GENE_EXPRESSION\\]' $ini_file | cut -f1 -d:`;
   
   printf "%8s %30s: ", "SPECIES:", $species;  
   ## Writing out config 
   if (chomp $found) {
     $found++; 
     my $command = "${found}s/.*/$gene_cats/";
     system("sed -i '$command' $ini_file");
     print "UPDATED\n";
   } else {
     system("echo [GENE_EXPRESSION] >> $ini_file");
     system("echo $gene_cats >> $ini_file");
     print "CREATED\n";
   }
}


