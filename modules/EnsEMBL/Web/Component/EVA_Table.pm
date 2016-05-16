package EnsEMBL::Web::Component::EVA_Table;

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
  
  my $columns = [
    { key => 'id',            title => 'Variant ID',              align => 'left',  width => '10%' },
    { key => 'study',         title => 'Study',                   align => 'left',  width => '10%' },
    { key => 'pos',           title => 'Genomic Position',        align => 'left',  width => '10%' },
    { key => 'type',          title => 'Type',                    align => 'left',  width => '10%' },
    { key => 'alleles',       title => 'Alleles',                 align => 'left',  width => '10%' },
    { key => 'consequence',   title => 'Most Severe Consequence', align => 'left',  width => '10%' },
  ];
  
  my @rows = map {[
    sprintf('<a href="%s">%s</a>', $_->{'url'}, $_->{'variation_name'}),
    $_->{'study_id'},
    $_->{'start'},
    $_->{'type'},
    sprintf('%s/%s', $_->{'ref'}, $_->{'alt'}),
    $_->{'severe'}
  ]} @{$self->features};
   
  my $table = $self->new_table($columns, \@rows, { data_table => 1 });
  return $table->render;
  
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

sub features {
  my $self         = shift;
  my $features_list = [];

  foreach my $eva_study (@{$self->hub->species_defs->EVA_TRACKS}) {
    my $study        = $eva_study->{'study_id'};
    my $species      = $eva_study->{'eva_species'};
    my $slice        = $self->object->slice;
  ### TODO: Check this way of getting synonyms works with all our species
    my $feature_name = @{$slice->get_all_synonyms('EMBL')}[0] || $slice->seq_region_name;
    my $start        = $slice->start;
    my $end          = $slice->end;
    my $slice_length = $slice->length;

##### TODO: Query by the gene or transcript ID in order to catch any of the up/downstream variants

    my $url = "http://www.ebi.ac.uk/eva/webservices/rest/v1/segments/$feature_name:$start-$end/variants?merge=true&exclude=sourceEntries&species=$species&studies=$study";
    my $uri = URI->new($url);

    my $can_accept;
    eval { $can_accept = HTTP::Message::decodable() };

    my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
    my $content  = $can_accept ? $response->decoded_content : $response->content;

    if ($response->is_error) {
      warn 'Error loading EVA track: ' . $response->status_line;
      return [];
    }

    my $data_structure = from_json($content);

    # Retrieve the consequence types and relevant ranking
    my %ct = map { $_->SO_term => $_->rank } values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;

    foreach my $result_set (@{$data_structure->{response}}) {
      if($result_set->{numResults} == 0) {
        next;
      }
      foreach my $variant (@{$result_set->{result}}) {
        # Get the most significant consequence type
        my $consequence_type;
        my @consequence_list;
        my $score = 9999;
        foreach my $consequence (@{$variant->{annotation}->{consequenceTypes}}) {
          foreach my $term (@{$consequence->{soTerms}}) {
            push(@consequence_list, $term->{soName});
            $term->{soName} =~ s/^[\d]KB_//;
            if($ct{$term->{soName}} < $score) {
              $consequence_type = $term->{soName};
              $score = $ct{$term->{soName}};
            }
          }
        }

        # Create the feature, then push to the features list
        my $info_url = $self->hub->url({ type => 'Location', action => 'EVA_Variant', variant_id => $variant->{id}, eva_species => $species });
        my $feature = {
          'start'          => $variant->{start},
          'end'            => $variant->{end},
          'class'          => 'group',
          'ref'            => $variant->{reference},
          'alt'            => $variant->{alternate},
          'feature_label'  => $variant->{alternate},
          'variation_name' => $variant->{id},
          'severe'         => $consequence_type,
          'type'           => $variant->{type},
          'colour_key'     => lc($consequence_type),
          'study_id'       => $study,
          'url'            => $info_url
        };
        push(@$features_list, $feature);
      }
    }
    
    return $features_list;
  }
}

1;