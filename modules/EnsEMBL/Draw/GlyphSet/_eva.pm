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

package EnsEMBL::Draw::GlyphSet::_eva;

### Draws a SNP track using data from EVA

use strict;
use EnsEMBL::LWP_UserAgent;
use List::Util qw(min);
use LWP;
use JSON;
use base qw(EnsEMBL::Draw::GlyphSet_simpler);

sub depth {
  my $self   = shift;
  my $length = $self->{'container'}->length;

  if ($self->{'display'} =~ /labels/ || ($self->{'display'} eq 'normal' && $length <= 2e5) || $length <= 101) {
    return $length > 1e4 ? 20 : undef;
  }

  return $self->SUPER::depth;
}

sub label_overlay { return 1; }

sub _init {
  my $self = shift;
  $self->{'my_config'}->set('no_label', 1) unless $self->{'show_labels'};
  return $self->SUPER::_init(@_);
}

sub features {
  my $self         = shift;
  my $max_length   = $self->my_config('threshold') || 1000;
  my $study        = $self->my_config('study_id');
  my $species      = $self->my_config('eva_species');
  my $slice        = $self->{'container'};
  #my $feature_name = @{$slice->get_all_synonyms('INSDC')}[0] || $slice->seq_region_name;
  my $feature_name = $slice->seq_region_name;
  $feature_name =~ s/^Smp\.Chr_//;  # Temporary hack until INSDC accessions are used in EVA
  my $start        = $slice->start;
  my $end          = $slice->end;
  my $slice_length = $slice->length;

  #Temporary hack to use INSDC contig names for PRJEB32744
  $feature_name = @{$slice->get_all_synonyms('INSDC')}[0]->{name} if $study eq 'PRJEB32744';
  
  if ($slice_length > $max_length * 1010) {
    $self->errorTrack("Variation features are not displayed for regions larger than ${max_length}Kb");
    return [];
  } else {

    my $url = sprintf("%s/webservices/rest/v1/segments/%s:%s-%s/variants?merge=true&exclude=sourceEntries&species=%s&studies=%s", $self->{'config'}->hub->species_defs->EVA_URL, $feature_name, $start, $end, $species, $study);
    my $uri = URI->new($url);
    
    my $can_accept;
    eval { $can_accept = HTTP::Message::decodable() };

    my $response = EnsEMBL::LWP_UserAgent->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
    my $content  = $can_accept ? $response->decoded_content : $response->content;
  
    if ($response->is_error) {
      warn 'Error loading EVA track: ' . $response->status_line;
      $self->errorTrack("Unable to load track");
      return [];
    }

    my $data_structure = from_json($content);

    # Retrieve the consequence types and relevant ranking
    my %ct = map { $_->SO_term => $_->rank } values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;
  
    my $features_list = [];
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
        my $info_url = $self->{'config'}->hub->url({ type => 'Location', action => 'EVA_Variant', variant_id => $variant->{id}, eva_species => $species, r => sprintf('%s:%s-%s', $self->{'container'}->seq_region_name, $variant->{start}, $variant->{end} || $variant->{start}) });
        my $feature = {
          'start'          => $variant->{start} - $start + 1,
          'end'            => $variant->{end} - $start + 1,
          'class'          => 'group',
          'feature_label'  => $variant->{alternate},
          'variation_name' => $variant->{id},
          'title'          => sprintf("Variation: %s; Location: %s; Type: %s; Consequence(s): %s; Most Severe Consequence: %s; Variant Information and Genotypes: %s",
                                     $variant->{id},
                                     $variant->{start},
                                     $variant->{type},
                                     join(', ', @consequence_list),
                                     $consequence_type,
                                     sprintf('<a href="%s">View Variant Information</a>', $info_url)
                              ),
          'colour_key'     => lc($consequence_type)
        };
        push(@$features_list, $feature);
      }
    }
    
    if (!scalar(@$features_list)) {
      my $track_name = $self->my_config('name');
      $self->errorTrack("No $track_name data for this region");
      return [];
    } else {
      $self->{'legend'}{'variation_legend'}{$_->{'colour_key'}} ||= $self->get_colours($_)->{'feature'} for @$features_list;
      return $features_list;
    }
  }
}

1;
