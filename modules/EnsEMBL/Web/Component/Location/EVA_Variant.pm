package EnsEMBL::Web::Component::Location::EVA_Variant;

use strict;
use LWP;
use JSON;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  
  my $variant_id = $hub->param('variant_id');
  my $eva_species = $hub->param('eva_species');
  return $self->get_variant_info($variant_id, $eva_species);
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
    { key => 'sample',    title => 'Sample Name', align => 'left',    width => '65%' },
    { key => 'genotype',  title => 'Genotype',    align => 'left',    width => '35%' },
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

      # Consequences
      $html .= "<h3>Consequences</h3>";
      my $consequence_table = $self->new_table($consequence_columns, [], { data_table => 1 });
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
          join('<br />', map($self->consequence_colour($_->{soName}, $colours, $colourmap), @{$consequence->{soTerms}}))
        ]);
      }
      $html .= $consequence_table->render;
      
      # Datasets
      foreach my $source (keys %{$result->{sourceEntries}}) {
        $html .= "<h3>Source: $source</h3>";
        
        # VCF Attributes
        my $attributes = $result->{sourceEntries}->{$source}->{attributes};
        foreach my $attrib (keys %{$attributes}) {
          push(@$attrib_columns, { key => $attrib, title => $attrib, align => 'left', width => '10%' });
          push(@$attrib_row, $attributes->{$attrib});
        }
        my $attrib_table = $self->new_table($attrib_columns, [$attrib_row]);
        $html .= $attrib_table->render;
        
        # Genotypes
        my $table = $self->new_table($gt_columns, [], { data_table => 1 });
        foreach my $sample (keys %{$result->{sourceEntries}->{$source}->{samplesData}}) {
          $table->add_row([
            $sample,
            $result->{sourceEntries}->{$source}->{samplesData}->{$sample}->{GT}
          ]);
        }
        $html .= $table->render;
      }
    }
  }
  
  return $html;
  
}

sub consequence_colour {
  my ($self, $term, $colours, $colourmap) = @_;
  (my $term_short = $term) =~ s/^[\d]KB_//;
  return $colours->{lc $term_short} ? sprintf(
                            '<span class="colour" style="background-color:%s">&nbsp;</span>&nbsp;<span>%s</span>',
                            $colourmap->hex_by_name($colours->{lc $term_short}->{'default'}),
                            $term
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
