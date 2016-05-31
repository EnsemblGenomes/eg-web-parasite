=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Parsers::Blast;

use strict;
use warnings;

use XML::Simple;

sub parse_xml {
  my ($self, $xml, $species, $source_type) = @_;
  my $hub  = $self->{hub};
  my $db   = $hub->database('core', $species);
  my $data = XMLin($xml, ForceArray => ['hit', 'alignment']); 
  my $hits = $data->{SequenceSimilaritySearchResult}->{hits}->{hit};
  my @results;

  foreach my $hit_id (keys %$hits) {
    my $hit = $hits->{$hit_id};
    
    my ($description) = $hit->{description} =~ /description:"(.+)"/;

## ParaSite: determine the species for each hit (rather than each job) as it is possible to have a single job query multiple species
    my ($species) = $hit->{description} =~ /species:(.+)/;  # This works becuase we have species:xxxxxx appended to the end of the FASTA header line in the dumps
    my $db = $hub->database('core', $species);
    $hit_id =~ s/$species://;
## ParaSite

    foreach my $align (@{ $hit->{alignments}->{alignment} }) {
      
      my $q      = $align->{querySeq};
      my $t      = $align->{matchSeq};

      my $qstart = $q->{start} < $q->{end} ? $q->{start} : $q->{end};
      my $qend   = $q->{start} < $q->{end} ? $q->{end} : $q->{start};
      my $qori   = $q->{start} < $q->{end} ? 1 : -1;

      my $tstart = $t->{start} < $t->{end} ? $t->{start} : $t->{end};
      my $tend   = $t->{start} < $t->{end} ? $t->{end} : $t->{start};
      my $tori   = $t->{start} < $t->{end} ? 1 : -1;

## ParaSite: a bug in BLAST+ can sometimes result in zero identity results outside the query sequence
      next if $hit->{length} < $tstart;
## ParaSite
 
      my ($qframe, $tframe) = split /\s*\/\s*/, $align->{frame} || ''; # E.g "+2 / -3"

      if ($align->{strand}) {
        my $strand = $1 if $align->{strand} =~ /.*?\/(.*)/i;
        my %replace = (
          'plus' => 1,
          'minus' => -1
        );
        $strand =~ s/$_/$replace{$_}/ for keys %replace;
        $tori = $strand if $strand !~ /^none$/;
      }

      my $result = {
        qid    => 'Query_1', #??
        qstart => $qstart,
        qend   => $qend,
        qori   => $qori,
        qframe => $qframe,
        tid    => $hit_id,
        tstart => $tstart,
        tend   => $tend,
        tori   => $tori,
        tframe => $tframe,
        score  => $align->{score},
        evalue => $align->{expectation},
        pident => $align->{identity},
        len    => length($q->{content}),
        aln    => btop($q->{content}, $t->{content}),
        desc   => $description,
      };
      push @results, $self->map_to_genome($result, $species, $source_type, $db);
    }
  }

  return \@results;
}

1;

