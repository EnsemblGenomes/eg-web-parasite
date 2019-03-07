use strict;
use warnings;
use Data::Dumper;

use Text::CSV qw/csv/;
use List::MoreUtils qw/uniq/;

#PATH to expression files from ftp
my $path = "/homes/ens_adm14/parasite/prev/browser/eg-web-parasite/htdocs/expression";
my @dirs = `ls $path`;

foreach my $species (@dirs) {
   chomp $species;
   my ($spe, $cies, $bp) = split "_", $species;
   my $tsv_path = "$path/$species/$spe\_$cies.studies.tsv"; 
   
   my @lines= @{csv(in=>$tsv_path, sep_char => "\t")} if -e $tsv_path;
   
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


