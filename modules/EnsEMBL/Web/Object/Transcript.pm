package EnsEMBL::Web::Object::Transcript;

use strict;

sub short_caption {
  my $self = shift;

  return 'Transcript-based displays' unless shift eq 'global';
  return ucfirst($self->Obj->type) . ': ' . $self->Obj->stable_id if $self->Obj->isa('EnsEMBL::Web::Fake');

  my $dxr   = $self->Obj->can('display_xref') ? $self->Obj->display_xref : undef;
  my $label = $dxr ? $dxr->display_id : $self->Obj->stable_id;

  return "Transcript: $label";  ## ParaSite: do not abbreviate to "Trans"
  #return length $label < 15 ? "Transcript: $label" : "Trans: $label" if($label);
}

1;
