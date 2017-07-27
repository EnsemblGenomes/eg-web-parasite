=head1 LICENSE

Copyright [2014-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Controller::Ajax;

use strict;
use LWP;
use URI::QueryParam;
use JSON;

sub ajax_search_autocomplete {
  my ($self, $hub) = @_;
  my $species_defs  = $hub->species_defs;
  my $term          = $hub->param('term');
  my $format        = $hub->param('format');
  my $ua = LWP::UserAgent->new();
     $ua->agent('EnsemblGenomes Web ' . $ua->agent());
     $ua->env_proxy;
     $ua->timeout(10);
  my $uri = URI->new($species_defs->EBEYE_REST_ENDPOINT . "/" . $species_defs->EBEYE_SEARCH_DOMAIN . "/autocomplete");
     $uri->query_param('term'   => $term);
     $uri->query_param('format' => $format);
  my $response = $ua->get($uri->as_string);
  if ($response->is_error) {
    die;
  }
  my $results = from_json($response->content);
  my @suggestions = map($_->{'suggestion'}, @{$results->{suggestions}});

  my @matches;

## Has the user entered the name of a tool?
  push(@matches, { value=>'FTP Downloads', url=>'/ftp.html', type=>'WormBase ParaSite Tools' }) if $term =~ /ftp|download/i;
  push(@matches, { value=>'BLAST Sequence Search', url=>'/Tools/Blast?db=core', type=>'WormBase ParaSite Tools' }) if $term =~ /blast/i;
  push(@matches, { valie=>'Variant Effect Predictor', url=>'/Tools/VEP', type=>'WormBase ParaSite Tools' }) if $term =~ /vep|variant|variation/i;
  push(@matches, { value=>'REST API', url=>'/rest', type=>'WormBase ParaSite Tools' }) if $term =~ /rest|api/i;
  push(@matches, { value=>'WormBase ParaSite BioMart', url=>'/biomart/martview', type=>'WormBase ParaSite Tools' }) if $term =~ /biomart|mart|wormmine|wormmart|intermine/i;
  push(@matches, { value=>'WormMine', url=>'http://www.wormbase.org/tools/wormmine', type=>'WormBase Tools' }) if $term =~ /wormmine|wormmart|intermine/i;
  push(@matches, { value=>'WormBase Central', url=>'http://www.wormbase.org', type=>'WormBase Tools' }) if $term =~ /wormbase|legacy/i;
  push(@matches, { value=>'Full Genome List', url=>'/species.html', type=>'Documentation' }) if $term =~ /species|genome|list|all/i;
  push(@matches, { value=>'Data Usage Policy', url=>'/info/about/datausage.html', type=>'Documentation' }) if $term =~ /data usage|citation|cite/i;
  push(@matches, { value=>'Frequently Asked Questions (FAQs)', url=>'/info/faqs/', type=>'Documentation' }) if $term =~ /faq|contact|email|help|question/i;
  push(@matches, { value=>'Contact Us', url=>'/Help/Contact', type=>'Documentation' }) if $term =~ /contact|email|question|help/i;
##

## Has the user entered some sequence (this is a very rough guess)
  if($term =~ /^[ACGTacgt]+$/) {  ## This could be nucleotide sequence
    if(length($term) <= 20) {
      push(@matches, { value=>"Send $term to nucleotide BLAST", url=>"/Tools/Blast?query_sequence=$term", type=>'Sequence Search' });
    } else {
      push(@matches, { value=>"Send sequence to nucleotide BLAST", url=>"/Tools/Blast?query_sequence=$term", type=>'Sequence Search' });
    }
  } elsif (length($term) > 10 && $term =~ /^[GPAVLIMCFYWHKRQNEDST*]+$/) {
    if(length($term) <= 20) {
      push(@matches, { value=>"Send $term to peptide BLAST", url=>"/Tools/Blast?query_sequence=$term", type=>'Sequence Search' });
    } else {
      push(@matches, { value=>"Send sequence to peptide BLAST", url=>"/Tools/Blast?query_sequence=$term", type=>'Sequence Search' });
    }
  }
##

## Does the search term match a species name?
  my @species = $species_defs->valid_species;  
  my ($sp_term, $sp_genus) = $term =~ /^([A-Za-z])[\.]?\s?([A-Za-z]+)/ ? ($2, $1) : ($term, undef); # Deal with abbreviation of the genus
  $sp_term =~ s/genome$//; # Some users put the word genome at the end of their search string - remove this so we still get a match
  foreach my $sp (@species) {
    my $name      = sprintf('%s (%s%s)', $species_defs->get_config($sp, "SPECIES_SCIENTIFIC_NAME"), $species_defs->get_config($sp, "SPECIES_BIOPROJECT"), $species_defs->get_config($sp, "SPECIES_STRAIN") ? " - " . $species_defs->get_config($sp, "SPECIES_STRAIN") : '');
    my $alt_names = $species_defs->get_config($sp, "SPECIES_ALTERNATIVE_NAME");
    my $bioproj   = sprintf('%s%s', $species_defs->get_config($sp, "SPECIES_BIOPROJECT"), $species_defs->get_config($sp, "SPECIES_STRAIN") ? " - " . $species_defs->get_config($sp, "SPECIES_STRAIN") : '');
    my @names     = map {qq/$_ \($bioproj\)/} @{$alt_names};
    unshift(@names, $name);
### Disabled linking out to WormBase
###    my $url       = $species_defs->ENSEMBL_SPECIES_SITE->{lc($sp)} eq 'WORMBASE' ? $hub->get_ExtURL(uc($sp) . "_URL", {'SPECIES'=>$sp}) : "/$sp"; # Link back to WormBase if this is a non-parasitic species
###
    my $url = "/$sp";
    foreach my $search (@names) {
      next unless $search =~ /\Q$sp_term\E/i;
      next if $sp_genus && ($search !~ /^$sp_genus/i || $search !~ /^(.*?) .*$sp_term.*/i);
      my $begins_with = $search =~ /^\Q$sp_term\E/i;
      push(@matches, {
        value => "$search",
        url => $url,
        type => 'Species',
        begins_with => $begins_with
      });
    }
  }
  my $sort = sub {
    my ($a, $b) = @_;
    return $a->{value} cmp $b->{value} if $a->{begins_with} == $b->{begins_with};
    return $a->{begins_with} ? -1 : 1;
  };
  @matches = sort {$sort->($a, $b)} @matches;
  unshift(@suggestions, @matches);
##

  print encode_json(\@suggestions);
}

sub ajax_species_tree {
  my ($self, $hub) = @_;

  my $species_defs = $hub->species_defs;
  my @species_info = ();
  # Get a list of group names
  my $labels       = $species_defs->TAXON_LABEL; ## sort out labels
  my (@group_order, %label_check);
  foreach my $taxon (@{$species_defs->TAXON_ORDER || []}) {
      my $label = $labels->{$taxon} || $taxon;
      push @group_order, $label unless $label_check{$label}++;
  }

  foreach my $group (@group_order) {

      my $display = defined($species_defs->TAXON_COMMON_NAME->{$group}) ? $species_defs->TAXON_COMMON_NAME->{$group} : $group;
      my @children = ();

      # Check for the presence of any sub-groups
      my @groups = ();
      my @subgroups;
      foreach my $taxon (@{$species_defs->TAXON_SUB_ORDER->{$group} || ['parent']}) {
        push @subgroups, $taxon;
      }

      foreach my $subgroup (@subgroups) {
        my $group_display = defined($species_defs->TAXON_COMMON_NAME->{$subgroup}) ? $species_defs->TAXON_COMMON_NAME->{$subgroup} : $subgroup;

        # Group the genome projects by species name
        my %species = ();
        my %aliases = ();
        my %providers = ();
        # Is this a multi-taxon group?
        my @taxons = @{$species_defs->TAXON_MULTI->{$subgroup} || [$subgroup]};
        foreach my $taxon (@taxons) {
          foreach ($species_defs->valid_species) {
            next unless defined($species_defs->get_config($_, 'SPECIES_GROUP'));
            ##next if $species_defs->ENSEMBL_SPECIES_SITE->{lc($_)} ne 'parasite';
            if($taxon eq 'parent') {
              next unless $species_defs->get_config($_, 'SPECIES_GROUP') eq $group;
            } else {
              next unless $species_defs->get_config($_, 'SPECIES_SUBGROUP') eq $taxon;
            }
            my $common = $species_defs->get_config($_, 'SPECIES_COMMON_NAME');
            next unless $common;
            my $scientific = $species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME');
            push(@{$species{$scientific}}, $_);
            push(@{$aliases{$scientific}}, @{$species_defs->get_config($_, 'SPECIES_ALTERNATIVE_NAME')}) if $species_defs->get_config($_, 'SPECIES_ALTERNATIVE_NAME');
            my $prov = $species_defs->get_config($_, 'PROVIDER_NAME');
            $providers{$_} = (ref($prov) eq 'ARRAY') ? join(" / ", @$prov) : $prov;
          }
        }

        # Print the species
        my $i = 0;
        my @genus = ();
        my %genuslist = map{ $_ =~ /(.*?)\s/ => 1 } keys(%species);
        foreach my $genusitem (sort(keys(%genuslist))) {
          my @specieslist = ();
          foreach my $scientific (sort(keys(%species))) {
            next unless $scientific =~ /^$genusitem/;
            my $species_url = scalar(@{$species{$scientific}}) == 1 ? "/@{$species{$scientific}}[0]/Info/Index/" : "/@{$species{$scientific}}[0]/Info/SpeciesLanding/";  # Only show a URL to the species landing page if there is more than one genome project
            my @speciesproj;
            foreach my $project (sort(@{$species{$scientific}})) {
              my $bioproject = $species_defs->get_config($project, 'SPECIES_BIOPROJECT');
              my $summary = "$providers{$project} genome project";
              push(@speciesproj, { 'label' => $bioproject, 'summary' => $summary, 'url' => "/$project/Info/Index", 'children' => undef });
            }
            my @alias = $aliases{$scientific} ? $aliases{$scientific} : [];
            push(@specieslist, { 'label' => $scientific, 'aliases' => @alias, 'url' => $species_url, 'children' => \@speciesproj });
          }
          push(@genus, {'label' => $genusitem, 'url' => '/', 'children' => \@specieslist });
        }
        push(@groups, {'label' => $group_display, 'url' => '/', 'children' => \@genus });
      }
      push(@species_info, { 'label' => $display, 'url' => '/', 'children' => \@groups });
  }

  print to_json(\@species_info, {utf8 => 1, pretty => 1});

}

sub ajax_assembly_stats {
  my ($self, $hub) = @_;
  my $species = $hub->param('species');

  my $file = "/ssi/species/assembly_${species}.json";
  my $content = (-e "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/$file") ? EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file) : '';

  print $content;

}



sub ajax_species_autocomplete {
  my ($self, $hub) = @_;
  my $species_defs  = $hub->species_defs;
  my $term          = $hub->param('term'); # will return everything if no term specified
  my $result_format = $hub->param('result_format') || 'simple'; # simple/chosen

  my @species = $species_defs->valid_species;

  # sub to normalise strings for comparison e.g. k-12 == k12
  my $normalise = sub {
    my $str = shift;
    $str =~ s/[^a-zA-Z0-9 ]//g;
    return $str;
  };

  $term = $normalise->($term);
  my @terms = split /\s+/, $term;

  my $paralogues = $species_defs->multi_hash->{'DATABASE_COMPARA'}->{'ENSEMBL_PARALOGUES'};

  # find matches
  my @matches;
  foreach my $sp (@species) {
    my $name    = $species_defs->get_config($sp, "SPECIES_COMMON_NAME");
## ParaSite
    my $bioproject = $species_defs->get_config($sp, "SPECIES_BIOPROJECT");
    my $strain  = $species_defs->get_config($sp, "SPECIES_STRAIN");
    $name = $strain ? sprintf('%s - %s', $name, $strain) : $name;
##
    my $taxid   = $species_defs->get_config($sp, "TAXONOMY_ID");
    my $search  = $normalise->("$name $taxid");

    my $hits = 0;
    for (@terms) {
      $hits ++ if $search =~ /\Q$_\E/i;
    }
    next unless $hits >= @terms;

    my $compara     = exists $paralogues->{$sp};
    my $begins_with = $search =~ /^\Q$term\E/i;

    my $score = 0;
    $score   += 2 if $compara;
    $score   += 1 if $begins_with;

    push(@matches, {
      value           => "$name, (TaxID $taxid)",
      production_name => $sp,
      score           => $score,
    });
  }

  # alphanumeric sort with score boost
  my $sort = sub {
    my ($a, $b) = @_;
    return $a->{value} cmp $b->{value} if $a->{score} == $b->{score};
    return $b->{score} <=> $a->{score};
  };

  @matches = sort {$sort->($a, $b)} @matches;

  my $data;

  if ($result_format eq 'chosen') {
    # return results in format compatible with chosen.ajaxaddition.jquery.js
    $data = {
      q => $hub->param('term'), # original term
      results => \@matches
    };
  } else {
    # default to simple array format
    $data = [@matches];
  }

  print $self->jsonify($data);
}

1;
