package EnsEMBL::Web::Document::Element::Navigation;

use strict;
use previous qw(build_menu);

sub build_menu {
  my ($self, $node, $hub, $config, $img_url, $modal, $counts, $all_params, $active, $is_last) = @_;
  
  my $data = $node->data;
  my $availability = $data->{'availability'};

## ParaSite: create a new option named 'hide_if_unavailable' which hides the left-hand menu entry (rather than greying it out) if the view is not available  
  return if $data->{'hide_if_unavailable'} && $availability && !$self->is_available($availability);
##
  
  $self->PREV::build_menu($node, $hub, $config, $img_url, $modal, $counts, $all_params, $active, $is_last);
}

1;
