package EnsEMBL::Web::Component::Transcript::ChEMBLHits;

use strict;

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
  return unless @hits;

  my $table = $self->new_table([], [], { data_table => 1 });
  
  $table->add_columns(
    { key => 'acc',      title => 'ChEMBL ID',   width => '10%',   sort => 'html'                          },
    { key => 'start',    title => 'Start',       width => '10%',   sort => 'numeric', hidden_key => '_loc' },
    { key => 'end',      title => 'End',         width => '10%',   sort => 'numeric'                       },
    { key => 'desc',     title => 'Description', width => '15%',   sort => 'string'                        },
    { key => 'score',    title => 'Score',       width => '15%',   sort => 'numeric'                       },
    { key => 'evalue',   title => 'E-Value',     width => '15%',   sort => 'numeric'                       },
    { key => 'percid',   title => '%ID',         width => '15%',   sort => 'numeric'                       },
  );
  
  foreach my $hit (
    sort {
      $a->idesc cmp $b->idesc || 
      $a->start <=> $b->start || 
      $a->end   <=> $b->end   || 
      $a->analysis->db cmp $b->analysis->db 
    } @hits
  ) {
    my $db            = $hit->analysis->db;
    
    $table->add_row({
      type     => $db,
      desc     => $hit->hdescription || $hit->idesc || '-',
      acc      => $hit->hseqname,
      start    => $hit->start,
      end      => $hit->end,
      score    => $hit->score,
      evalue   => $hit->p_value,
      percid   => $hit->percent_id,
      _loc     => join('::', $hit->start, $hit->end),
    });
    
  }
  
  return $table->render;
}

1;

