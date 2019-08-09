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

package EnsEMBL::Web::Component::Location::EVA_Variant;

use strict;
use EnsEMBL::LWP_UserAgent;
use LWP;
use HTML::Entities;
use JSON;
use XML::Simple;
use List::MoreUtils qw(uniq);

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  
  my $variant_id = $hub->param('variant_id');
  my $region = $hub->param('r');
  my $eva_species = $hub->param('eva_species');
  return $self->get_variant_info($eva_species, $region, $variant_id);
}

sub get_variant_info {
  my ($self, $eva_species, $region, $variant_id) = @_;
  
  my $url;
  if($variant_id) {
    $url = sprintf("%s/webservices/rest/v1/variants/%s/info?species=%s", $self->hub->species_defs->EVA_URL, $variant_id, $eva_species);
  } else {
    my $object = $self->object || $self->hub->core_object('location');
    #my $feature_name = @{$object->slice->get_all_synonyms('INSDC')}[0] || $object->slice->seq_region_name;
    my $feature_name = $object->slice->seq_region_name;
    $feature_name =~ s/^Smp\.Chr_//;  # Temporary hack until INSDC accessions are used in EVA
    my $start = $object->slice->start;
    my $end = $object->slice->end;
    $url = sprintf("%s/webservices/rest/v1/segments/%s:%s-%s/variants?merge=true&species=%s", $self->hub->species_defs->EVA_URL, $feature_name, $start, $end, $eva_species);
  }
  my $uri = URI->new($url);

  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  my $response = EnsEMBL::LWP_UserAgent->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;

  if ($response->is_error) {
    warn 'Error loading EVA data: ' . $response->status_line;
    return 'Unable to load variant data from EVA';
  }

  my $data_structure = from_json($content);
  
  my $vcf_help = {
    'QUAL'      => 'phred-scaled quality score for the assertion made in ALT. i.e. give -10log_10 prob(call in ALT is wrong). If ALT is "." (no variant) then this is -10log_10 p(variant), and if ALT is not "." this is -10log_10 p(no variant). High QUAL scores indicate high confidence calls. Although traditionally people use integer phred scores, this field is permitted to be a floating point to enable higher resolution for low confidence calls if desired.', 
    'FILTER'    => 'PASS if this position has passed all filters, i.e. a call is made at this position. Otherwise, if the site has not passed all filters, a semicolon-separated list of codes for filters that fail. e.g. "q10;s50" might indicate that at this site the quality is below 10 and the number of samples with data is below 50% of the total number of samples. "0" is reserved and should not be used as a filter String. If filters have not been applied, then this field should be set to the missing value.', 
    'AA'        => 'Ancestral allele', 
    'AC'        => 'Allele count in genotypes, for each ALT allele, in the same order as listed', 
    'AF'        => 'Allele frequency for each ALT allele in the same order as listed: use this when estimated from primary data, not called genotypes', 
    'AN'        => 'Total number of alleles in called genotypes', 
    'BQ'        => 'RMS base quality at this position', 
    'CIGAR'     => 'CIGAR string describing how to align an alternate allele to the reference allele', 
    'DB'        => 'dbSNP membership', 
    'DP'        => 'Combined depth across samples, e.g. DP=154', 
    'END'       => 'End position of the variant described in this record (esp. for CNVs)', 
    'H2'        => 'Membership in hapmap2', 
    'MQ'        => 'RMS mapping quality, e.g. MQ=52', 
    'MQ0'       => 'Number of MAPQ == 0 reads covering this record', 
    'NS'        => 'Number of samples with data', 
    'SB'        => 'Strand bias at this position', 
    'SOMATIC'   => 'Indicates that the record is a somatic mutation, for cancer genomics', 
    'VALIDATED' => 'Validated by follow-up experiment',
    'GT'        => 'Genotype, shown as alleles values separated by either of "/" or "|".  If a call cannot be made for a sample at a given locus, "." is specified for each missing allele in the GT field (for example ./. for a diploid). The meanings of the separators are:<br />/ : genotype unphased<br />| : genotype phased'
  };
  
  my %consequences = map { $_->SO_term => $_->description } values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;
  
  my $anno_columns = [
    { key => 'id',            title => 'Variant ID',          align => 'left',    width => '10%' },
    { key => 'chr',           title => 'Scaffold/Chromosome', align => 'left',    width => '10%' },
    { key => 'start',         title => 'Start',               align => 'left',    width => '10%' },
    { key => 'end',           title => 'End',                 align => 'left',    width => '10%' },
    { key => 'ref',           title => 'Reference Allele',    align => 'left',    width => '10%' },
    { key => 'alt',           title => 'Alternative Allele',  align => 'left',    width => '10%' },
  ];
  my $consequence_columns = [
    { key => 'geneid',    title => 'Gene ID',       align => 'left',    width => '10%' },
    { key => 'transid',   title => 'Transcript ID', align => 'left',    width => '10%' },
    { key => 'strand',    title => 'Strand',        align => 'left',    width => '10%' },
    { key => 'biotype',   title => 'Biotype',       align => 'left',    width => '10%' },
    { key => 'cdna',      title => 'cDNA Position', align => 'left',    width => '10%' },
    { key => 'cds',       title => 'CDS Position',  align => 'left',    width => '10%' },
    { key => 'aapos',     title => 'AA Position',   align => 'left',    width => '10%' },
    { key => 'aachange',  title => 'AA Change',     align => 'left',    width => '10%' },
    { key => 'codon',     title => 'Codon Change',  align => 'left',    width => '10%' },
    { key => 'soTerm',    title => 'SO Term(s)',    align => 'left',    width => '10%' },
  ];
  my $gt_columns = [
    { key => 'sample',    title => 'Sample Name',   align => 'left',    width => '40%' },
    { key => 'genotype',  title => 'Genotype',      align => 'left',    width => '10%', help => $vcf_help->{'GT'} },
  ];
  my $attrib_columns = [];
  my $attrib_row     = [];
   
  my $colours = $self->hub->species_defs->colour('variation');
  my $colourmap = $self->hub->colourmap;

  my $html;
  foreach my $result_set (@{$data_structure->{response}}) {
    if($result_set->{numResults} == 0) {
      next;
    }
    $html .= sprintf('<p>There %s %s %s located at this position.</p>', $result_set->{numResults} == 1 ? 'is' : 'are', $result_set->{numResults} == 1 ? 'variant' : 'variants', $result_set->{numResults});
    my $j = 0;
    foreach my $result (@{$result_set->{result}}) {  
      $j++;
      $html .= $result_set->{numResults} > 1 ? "<hr><h2>Variant $j</h2>" : '';
      # Annotation
      my $annotation = $result->{annotation};
      my $anno_table = $self->new_table($anno_columns, [[
        $result->{id} || '-',
        $result->{chromosome},
        $result->{start},
        $result->{end} == 0 ? '-' : $result->{end},
        $result->{reference} || '-',
        $result->{alternate} || '-'
      ]]);
      $html .= $anno_table->render;
      my $ref = $annotation->{referenceAllele} || '-';
      my $alt = $annotation->{alternativeAllele} || '-';

      # Consequences
      $html .= "<h3>Consequences</h3>";
      my $consequence_table = $self->new_table($consequence_columns, [], { data_table => 1 });
      my @transcripts;
      foreach my $consequence (@{$annotation->{consequenceTypes}}) {
        my $gene_url = $self->hub->url({ type => 'Gene', action => 'Summary', g => $consequence->{ensemblGeneId}, __clear => 1 });
        my $transcript_url = $self->hub->url({ type => 'Transcript', action => 'Summary', g => $consequence->{ensemblTranscriptId}, __clear => 1 });
        $consequence_table->add_row([
          sprintf('<a href="%s">%s</a>', $gene_url, $consequence->{ensemblGeneId}),
          sprintf('<a href="%s">%s</a>', $transcript_url, $consequence->{ensemblTranscriptId}),
          $consequence->{strand},
          $consequence->{biotype},
          $consequence->{cDnaPosition} == 0 ? '-' : $consequence->{cDnaPosition},
          $consequence->{cdsPosition} == 0 ? '-' : $consequence->{cdsPosition},
          $consequence->{aaPosition} == 0 ? '-' : $consequence->{aaPosition},
          $consequence->{aaChange},
          $consequence->{codon},
          join('<br />', map($self->consequence_colour($_->{soName}, \%consequences, $colours, $colourmap), @{$consequence->{soTerms}}))
        ]);
        push(@transcripts, $consequence->{ensemblTranscriptId});
      }
      $html .= sprintf("<p>This variant affects %s transcripts</p>", scalar(uniq @transcripts));
      $html .= $consequence_table->render;
      
      # Datasets
      foreach my $source (keys %{$result->{sourceEntries}}) {
        $html .= "<h2>Study $source</h2>";
        
        my $ena_url = sprintf("%s/data/view/%s&display=xml", $self->hub->species_defs->ENA_URL, $result->{sourceEntries}->{$source}->{studyId});
        my $ua = LWP::UserAgent->new();
        my $response = $ua->get($ena_url);
        if ($response->is_success) {
          my $result = XMLin($response->decoded_content);
          my $submitter = $result->{PROJECT}{center_name};
          my $name = $result->{PROJECT}->{NAME} || $result->{PROJECT}->{TITLE};
          my $formatted;
          if($result->{PROJECT}->{DESCRIPTION}) {
            $formatted = encode_entities($result->{PROJECT}->{DESCRIPTION});
          } elsif($result->{STUDY}->{DESCRIPTOR}->{STUDY_DESCRIPTION}) {
            $formatted = encode_entities($result->{STUDY}->{DESCRIPTOR}->{STUDY_DESCRIPTION});
          }
          $html .= qq(<h3>Study Overview</h3><p><span style="font-weight: bold">Study Name:</span> $name<br /><span style="font-weight: bold">Submitter:</span> $submitter</p>);
        }

        $html .= "<h3>Quality Overview</h3>";
        
        # VCF Attributes
        my $attributes = $result->{sourceEntries}->{$source}->{attributes};
        foreach my $attrib (sort keys %{$attributes}) {
          next if $attrib eq 'src';
          push(@$attrib_columns, { key => $attrib, title => $attrib, align => 'left', width => '10%', help => $vcf_help->{$attrib} ? $vcf_help->{$attrib} : '' });
          push(@$attrib_row, $attributes->{$attrib});
        }
        my $attrib_table = $self->new_table($attrib_columns, [$attrib_row]);
        $html .= $attrib_table->render;
        
        # Genotypes
        $html .= "<h3>Genotypes</h3>";
        $html .= sprintf("<p>This study included %s samples.  The genotype for each is shown in the table below.</p>", scalar(keys %{$result->{sourceEntries}->{$source}->{samplesData}}));
        my @alleles = ( $ref, $alt );
        push(@alleles, @{$result->{sourceEntries}->{$source}->{secondaryAlternates}}) if ($result->{sourceEntries}->{$source}->{secondaryAlternates});
        my $table = $self->new_table($gt_columns, [], { data_table => 1 });
        foreach my $sample (keys %{$result->{sourceEntries}->{$source}->{samplesData}}) {
          my $gt = $result->{sourceEntries}->{$source}->{samplesData}->{$sample}->{GT};
          my $delimeter = $1 if $gt =~ /.*([|\/]).*/;
          my @genotypes = split(/[|\/]/, $gt);
          foreach(@genotypes) {
            $_ =~ s/-1/./;
            $_ =~ s/\./0/;  # Replace 'no call' with reference allele
            for(my $i = 0; $i < scalar(@alleles); $i++) {
              my $col = $i == 0 ? 'green' : 'red';
              $_ =~ s/$i/<span style="color: $col">$alleles[$i]<\/span>/;
            }
          }
          my $actual_gt = join($delimeter, @genotypes);
          $table->add_row([
            $sample,
            $actual_gt
          ]);
        }
        $html .= $table->render;
      }
    }
  }
  
  $html .= sprintf('<p>Data loaded from the <a href="%s">European Variation Archive</a></p>', $self->hub->species_defs->EVA_URL);

  return $html;
  
}

sub consequence_colour {
  my ($self, $term, $consequences, $colours, $colourmap) = @_;
  (my $term_short = $term) =~ s/^[\d]KB_//;
  return $colours->{lc $term_short} ? sprintf(
                            '<span class="colour" style="background-color:%s">&nbsp;</span>&nbsp;<span>%s</span>',
                            $colourmap->hex_by_name($colours->{lc $term_short}->{'default'}),
                            $self->helptip($term, $consequences->{$term_short})
                          ) : $term;
}

1;
