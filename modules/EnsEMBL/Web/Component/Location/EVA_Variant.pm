package EnsEMBL::Web::Component::Location::EVA_Variant;

use strict;
use LWP;
use JSON;
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
  my $eva_species = $hub->param('eva_species');
  return $self->get_variant_info($variant_id, $eva_species);
}

sub caption {
  my $self = shift;
  return sprintf("Variant %s", $self->param->('variant_id'));
}

sub get_variant_info {
  my ($self, $variant_id, $eva_species) = @_;
    
  my $url = "http://www.ebi.ac.uk/eva/webservices/rest/v1/variants/$variant_id/info?species=$eva_species";
  my $uri = URI->new($url);

  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;

  if ($response->is_error) {
    warn 'Error loading EVA data: ' . $response->status_line;
    return 'Unable to load variant data from EVA';
  }

  my $data_structure = from_json($content);
  
  my $vcf_help = {
    'QUAL' => 'phred-scaled quality score for the assertion made in ALT. i.e. give -10log_10 prob(call in ALT is wrong). If ALT is ”.” (no variant) then this is -10log_10 p(variant), and if ALT is not ”.” this is -10log_10 p(no variant). High QUAL scores indicate high confidence calls. Although traditionally people use integer phred scores, this field is permitted to be a floating point to enable higher resolution for low confidence calls if desired.', 
    'FILTER' => 'PASS if this position has passed all filters, i.e. a call is made at this position. Otherwise, if the site has not passed all filters, a semicolon-separated list of codes for filters that fail. e.g. “q10;s50” might indicate that at this site the quality is below 10 and the number of samples with data is below 50% of the total number of samples. “0” is reserved and should not be used as a filter String. If filters have not been applied, then this field should be set to the missing value.', 
    'AA' => 'ancestral allele', 
    'AC' => 'allele count in genotypes, for each ALT allele, in the same order as listed', 
    'AF' => 'allele frequency for each ALT allele in the same order as listed: use this when estimated from primary data, not called genotypes', 
    'AN' => 'total number of alleles in called genotypes', 
    'BQ' => 'RMS base quality at this position', 
    'CIGAR' => 'cigar string describing how to align an alternate allele to the reference allele', 
    'DB' => 'dbSNP membership', 
    'DP' => 'combined depth across samples, e.g. DP=154', 
    'END' => 'end position of the variant described in this record (esp. for CNVs)', 
    'H2' => 'membership in hapmap2', 
    'MQ' => 'RMS mapping quality, e.g. MQ=52', 
    'MQ0' => 'Number of MAPQ == 0 reads covering this record', 
    'NS' => 'Number of samples with data', 
    'SB' => 'strand bias at this position', 
    'SOMATIC' => 'indicates that the record is a somatic mutation, for cancer genomics', 
    'VALIDATED' => 'validated by follow-up experiment',
    'GT' => 'Genotype, shown as alleles values separated by either of "/" or "|".  If a call cannot be made for a sample at a given locus, "." is specified for each missing allele in the GT field (for example ./. for a diploid). The meanings of the separators are:<br />/ : genotype unphased<br />| : genotype phased'
  };
  
  my %consequences = map { $_->SO_term => $_->description } values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;
  
  my $anno_columns = [
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
    foreach my $result (@{$result_set->{result}}) {  
      # Annotation
      my $annotation = $result->{annotation};
      my $anno_table = $self->new_table($anno_columns, [[
        $annotation->{chromosome},
        $annotation->{start},
        $annotation->{end} == 0 ? '-' : $annotation->{end},
        $annotation->{referenceAllele},
        $annotation->{alternativeAllele}
      ]]);
      $html .= $anno_table->render;
      my $ref = $annotation->{referenceAllele};
      my $alt = $annotation->{alternativeAllele};

      # Consequences
      $html .= "<h3>Consequences</h3>";
      my $consequence_table = $self->new_table($consequence_columns, [], { data_table => 1 });
      my @transcripts;
      foreach my $consequence (@{$annotation->{consequenceTypes}}) {
        my $gene_url = $self->hub->url({ type => 'Gene', action => 'Summary', g => $consequence->{ensemblGeneId} });
        my $transcript_url = $self->hub->url({ type => 'Transcript', action => 'Summary', g => $consequence->{ensemblTranscriptId} });
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
        $html .= "<h3>Quality Overview</h3>";
        
        # VCF Attributes
        my $attributes = $result->{sourceEntries}->{$source}->{attributes};
        foreach my $attrib (keys %{$attributes}) {
          push(@$attrib_columns, { key => $attrib, title => $attrib, align => 'left', width => '10%', help => $vcf_help->{$attrib} ? $vcf_help->{$attrib} : '' });
          push(@$attrib_row, $attributes->{$attrib});
        }
        my $attrib_table = $self->new_table($attrib_columns, [$attrib_row]);
        $html .= $attrib_table->render;
        
        # Genotypes
        $html .= "<h3>Genotypes</h3>";
        $html .= sprintf("<p>This study included %s individuals.  The genotype for each is shown in the table below.</p>", scalar(keys %{$result->{sourceEntries}->{$source}->{samplesData}}));
        my $table = $self->new_table($gt_columns, [], { data_table => 1 });
        foreach my $sample (keys %{$result->{sourceEntries}->{$source}->{samplesData}}) {
          my $gt = $result->{sourceEntries}->{$source}->{samplesData}->{$sample}->{GT};
          my $delimeter = $1 if $gt =~ /.*([|\/]).*/;
          my @genotypes = split(/[|\/]/, $gt);
          foreach(@genotypes) {
            $_ =~ s/0/<span style="color: green">$ref<\/span>/;
            $_ =~ s/1/<span style="color: red">$alt<\/span>/;
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

sub user_agent {
  my $self = shift;

  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new();
    $ua->agent('WormBase ParaSite (EMBL-EBI) Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->timeout(10);
    $self->{user_agent} = $ua;
  }

  return $self->{user_agent};
}

1;
