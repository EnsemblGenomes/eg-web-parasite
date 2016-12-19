package EnsEMBL::Web::Component::Transcript::ChEMBLHits;

use strict;
use EnsEMBL::LWP_UserAgent;
use LWP;
use JSON;

use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $translation = $object->translation_object;
  
  return $self->non_coding_error unless $translation;
  
  my $hub      = $self->hub;
  
  my @hits = @{$translation->get_all_ProteinFeatures('chembl')};
  return "There are no hits in ChEMBL for this transcript" unless @hits;

  my $table = $self->new_table([], [], { data_table => 1, sorting => ['score desc']});
  
  $table->add_columns(
    { key => 'acc',      title => 'ChEMBL ID',   width => '10%',   sort => 'html'                          },
    { key => 'uniprot',  title => 'UniProt ID',  width => '10%',   sort => 'html'                          },
    { key => 'species',  title => 'Species',     width => '15%',   sort => 'string'                        },
    { key => 'desc',     title => 'Description', width => '20%',   sort => 'string'                        },
    { key => 'start',    title => 'Start',       width => '5%',    sort => 'numeric', hidden_key => '_loc' },
    { key => 'end',      title => 'End',         width => '5%',    sort => 'numeric'                       },
    { key => 'score',    title => 'Score',       width => '5%',    sort => 'numeric'                       },
    { key => 'evalue',   title => 'E-Value',     width => '10%',   sort => 'numeric'                       },
    { key => 'percid',   title => '%ID',         width => '5%',    sort => 'numeric'                       },
  );
  
  # Avoid making lots of requests to ChEMBL - just determine everything we need now, make one request to ChEMBL then store it in a hash
  my @chembl_ids = map { $_->hseqname =~ /^(\w*):{0,1}(\w*)$/; $1 } @hits;
  my $chembl_targets_response = $self->get_external_ChEMBL_data('target/set', join(";", @chembl_ids));
  my %chembl_targets;
  my %chembl_uniprot_mapping;
  foreach (@{$chembl_targets_response->{'targets'}}) {
    $chembl_targets{$_->{'target_chembl_id'}} = $_;
    foreach (@{$_->{'target_components'}}) {
      $chembl_uniprot_mapping{$_->{'accession'}} = $_->{'component_id'};
    }
  }

  my $e_value = $hub->param('e_value');
  my $html = sprintf('<h3>%s</h3>', $e_value > 0 ? "E-value cut-off threshold: $e_value" : "No E-value cut-off threshold");
  
  foreach my $hit (@hits) {
    my $db = $hit->analysis->db;
    
    next if $e_value > 0 && $hit->p_value > $e_value;
    
    my ($chembl_target_id, $chembl_uniprot_id) = split(":", $hit->hseqname);
    my $chembl_target_data = $chembl_targets{$chembl_target_id};

    # TODO: disabled as we're not doing anything with this data yet
    #my $chembl_component_data = $self->get_external_ChEMBL_data('target_component', $chembl_uniprot_mapping{$chembl_uniprot_id}) if $chembl_uniprot_id;
    
    $table->add_row({
      type     => $db,
      desc     => $chembl_target_data->{'pref_name'} || '-',
      acc      => $chembl_target_id,
      uniprot  => $chembl_uniprot_id || '-',
      start    => $hit->start,
      end      => $hit->end,
      score    => $hit->score,
      evalue   => $hit->p_value,
      percid   => $hit->percent_id,
      species  => $chembl_target_data->{'organism'} || '-',
      _loc     => join('::', $hit->start, $hit->end),
    });
    
  }
  
  $html .= $table->render;
  return $html;
}

sub get_external_ChEMBL_data {
  my ($self, $endpoint, $id) = @_;
  
  my $url = sprintf("%s/%s/%s?format=json", $self->hub->species_defs->CHEMBL_REST_URL, $endpoint, $id);
  my $uri = URI->new($url);

  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  my $response = EnsEMBL::LWP_UserAgent->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;

  if ($response->is_error) {
    warn sprintf('Error loading ChEMBL data from %s: %s', $uri->as_string, $response->status_line);
    return {};
  }

  return from_json($content);
}

1;

