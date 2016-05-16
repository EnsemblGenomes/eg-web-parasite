package EnsEMBL::Web::Component::Gene::TranscriptComparison;

use strict;

sub content {
  my $self   = shift;
  my $slice  = $self->object->slice; # Object for this section is the slice
  my $length = $slice->length;
  my $html   = '';

  if (!$self->hub->param('t1')) {
## ParaSite: instead of showing an error, select all transcripts if none are selected by default
    my @transcripts = map { $_->stable_id } @{$self->object->gene->get_all_Transcripts};
    my $counter = 1;
    foreach(@transcripts) {
      $self->hub->param("t$counter", $_);
      $counter++;
    }
    #$html = $self->_info(
    #  'No transcripts selected',
    #  sprintf(
    #    'You must select transcripts using the "Select transcripts" button from menu on the left hand side of this page, or by clicking <a href="%s" class="modal_link" rel="modal_select_transcripts">here</a>.',
    #    $self->view_config->extra_tabs->[1]
    #  )
    #);
  } 
  if ($length >= $self->{'subslice_length'}) {
##
    $html .= '<div class="_adornment_key adornment-key"></div>' . $self->chunked_content($length, $self->{'subslice_length'}, { length => $length });
  } else {
    $html .= $self->content_sub_slice; # Direct call if the sequence length is short enough
  }

  return $html;
}

1;
