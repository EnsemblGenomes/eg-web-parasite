package EnsEMBL::Web::Component::Transcript::ChEMBLHits;

use strict;
use LWP;
use XML::Simple;

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

  my $table = $self->new_table([], [], { data_table => 1 });
  
  $table->add_columns(
    { key => 'acc',      title => 'ChEMBL ID',   width => '10%',   sort => 'html'                          },
    { key => 'species',  title => 'Species',     width => '10%',   sort => 'string'                        },
    { key => 'desc',     title => 'Description', width => '15%',   sort => 'string'                        },
    { key => 'start',    title => 'Hit Start',   width => '10%',   sort => 'numeric', hidden_key => '_loc' },
    { key => 'end',      title => 'Hit End',     width => '10%',   sort => 'numeric'                       },
    { key => 'score',    title => 'Score',       width => '15%',   sort => 'numeric'                       },
    { key => 'evalue',   title => 'E-Value',     width => '15%',   sort => 'numeric'                       },
    { key => 'percid',   title => '%ID',         width => '15%',   sort => 'numeric'                       },
  );
  
  foreach my $hit (
    sort {
      $a->idesc cmp $b->idesc ||
      $b->score <=> $a->score || 
      $a->start <=> $b->start || 
      $a->end   <=> $b->end   || 
      $a->analysis->db cmp $b->analysis->db 
    } @hits
  ) {
    my $db            = $hit->analysis->db;
    my $chembl_data   = $self->get_external_ChEMBL_data('target', $hit->hseqname);
   
    $table->add_row({
      type     => $db,
      desc     => $chembl_data->{'pref_name'},
      acc      => $hit->hseqname,
      start    => $hit->start,
      end      => $hit->end,
      score    => $hit->score,
      evalue   => $hit->p_value,
      percid   => $hit->percent_id,
      species  => $chembl_data->{'organism'},
      _loc     => join('::', $hit->start, $hit->end),
    });
    
  }
  
  return $table->render;
}

sub user_agent {
  my $self = shift;

  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new();
    $ua->agent('WormBase ParaSite (EMBL-EBI) Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->timeout(2);
    $self->{user_agent} = $ua;
  }

  return $self->{user_agent};
}

sub get_external_ChEMBL_data {
  my ($self, $chembl_endpoint, $chembl_target_id) = @_;
  
  my $url = sprintf("https://www.ebi.ac.uk/chembl/api/data/%s/%s", $chembl_endpoint, $chembl_target_id);
  my $uri = URI->new($url);

  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;

  if ($response->is_error) {
    warn 'Error loading ChEMBL data: ' . $response->status_line;
    return [];
  }

  my $data_structure = XMLin($content);
}

1;

