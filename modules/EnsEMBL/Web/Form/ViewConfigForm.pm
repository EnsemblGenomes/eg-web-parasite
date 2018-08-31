package EnsEMBL::Web::Form::ViewConfigForm;

use strict;
use warnings;
no warnings "uninitialized";

sub _build_imageconfig_menus {
  my ($self, $node, $parent, $menu_class, $submenu_class) = @_;
  my $menu_type = $node->get_data('menu');
  my $id        = $node->id;

  return if $menu_type eq 'no';

  if ($menu_type eq 'matrix_subtrack') {
    my $display = $node->get('display');
    if ($display ne 'off' && $display ne 'default'

#    if ($node->get_node($node->get_data('option_key')) &&
#      $node->get_node($node->get_data('option_key'))->get('display') eq 'on' &&  # The cell option is turned on AND
#      $display ne 'off' &&                                                       # The track is not turned off AND
#      !($display eq 'default' && $node->get_node($node->get_data('column_key'))->get('display') eq 'off') 
                                                # The track renderer is not default while the column renderer is off
    ) {
      $self->{'enabled_tracks'}{$menu_class}++;
      $self->{'enabled_tracks'}{$id} = 1;

      $self->{'json'}{'subTracks'}{$node->get_data('column_key')}++ if $display eq 'default'; # use an array of tracks rather than a hash so that gzip can compress the json mmore effectively.
    } else {
      $self->{'json'}{'subTracks'}{$node->get_data('column_key')} ||= 0; # Force subTracks entries to exist
    }

    $self->{'total_tracks'}{$menu_class}++;

    return;
  }

  my $external = $node->get_data('external');

  if ($node->get_data('node_type') eq 'menu') {
    my $caption = $node->get_data('caption');
    my $element;

    if ($parent->node_name eq 'ul') {
      if ($external) {
        $parent = $parent->parent_node;                                # Move external tracks to a separate ul, after other tracks
      } else {
        $parent = $parent->append_child('li', { 'flags' => 'display' }); # Children within a subset (eg variation sets)
      }
    }

    # If the children are all non external menus, add another wrapping div so there can be distinct groups in a submenu, with unlinked enable/disable all controls
    if (!scalar(grep $_->get_data('node_type') ne 'menu', @{$node->child_nodes}) && scalar(grep !$_->get_data('external'), @{$node->child_nodes})) {
      $element = $parent->append_child('div', { class => $menu_type eq 'hidden' ? ' hidden' : '' });
    } else {
      $element = $parent->append_child('ul', { class => "config_menu $menu_class" . ($menu_type eq 'hidden' ? ' hidden' : '') });
    }

    $self->_build_imageconfig_menus($_, $element, $menu_class, $submenu_class) for grep !$_->get_data('cloned'), @{$node->child_nodes};
    $self->_add_select_all($node, $element, $id) if $element->node_name eq 'ul';
  } else {
    my $img_url     = $self->view_config->species_defs->img_url;
    my @states      = @{$node->get_data('renderers') || [ 'off', 'Off', 'normal', 'On' ]};
    my %valid       = @states;
    my $display     = $node->get('display') || 'off';
       $display     = $valid{'normal'} ? 'normal' : $states[2] unless $valid{$display};
    my $controls    = $node->get_data('controls');
    my $subset      = $node->get_data('subset');
    my $name        = $node->get_data('name');
    my $caption     = encode_entities($node->get_data('caption'));
    $name           .= $name ne $caption ? "<span class='hidden-caption'> ($caption)</span>" : '';
    my @classes     = ('track', $external ? 'external' : '', lc $external);
    my $menu_header = scalar @states > 4 ? qq(<li class="header">Change track style<img class="close" src="${img_url}close.png" title="Close" alt="Close" /></li>) : '';
    my ($selected, $menu, $help);

    while (my ($renderer, $label) = splice @states, 0, 2) {
      $label = encode_entities($label);
      $menu .= qq{<li class="$renderer">$label</li>};

      push @classes, $renderer if $renderer eq $display;

      my $p = $node;

      while ($p = $p->parent_node) {
        $self->{'track_renderers'}{$p->id}{$renderer}++;
        last if $external;
      }
    }

    $menu .= qq{<li class="setting subset subset_$subset"><a href="#">Configure track options</a></li>} if $subset;

    if ($node->get_data('matrix') ne 'column') {
      if ($display ne 'off') {
        $self->{'enabled_tracks'}{$menu_class}++;
        $self->{'enabled_tracks'}{$id} = 1;
      }

      $self->{'total_tracks'}{$menu_class}++;
    }

    my $desc      = '';
    my $node_desc = $node->get_data('description');
    my $desc_url  = $node->get_data('desc_url') ? $self->view_config->hub->url('Ajax', {'type' => 'fetch_html', 'url' => $node->get_data('desc_url')}) : '';

    if ($node->get_data('subtrack_list')) { # it's a composite track
      $desc .= '<h1>Track list</h1>';
      $desc .= sprintf '<ul>%s</ul>', join '', map $_->[1], sort { $a->[0] cmp $b->[0] } map [ lc $_->[0], $_->[1] ? "<li><p><b>$_->[0]</b></p><p>$_->[1]</p></li>" : "<li>$_->[0]</li>" ], @{$node->get_data('subtrack_list')};
      $desc .= "<h1>Trackhub description: $node_desc</h1>" if $node_desc && $desc_url;
      $desc .= qq(<div class="_dyna_load"><a class="hidden" href="$desc_url">No description found for this composite track.</a>Loading&#133;</div>) if $desc_url;
    } else {
      $desc .= $desc_url ? sprintf(q(<div class="_dyna_load"><a class="hidden" href="%s">%s</a>Loading&#133;</div>), $desc_url, encode_entities($node_desc)) : $node_desc;
    }

    if ($desc) {
      $desc = qq{<div class="desc">$desc</div>};
      $help = qq{<div class="sprite info_icon menu_help _ht" title="Click for more information"></div>};
    } else {
      $help = qq{<div class="empty info_icon sprite"></div>};
    }

    push @classes, 'on'             if $display ne 'off';
    push @classes, 'fav'            if $self->{'favourite_tracks'}{$id};
    push @classes, 'hidden'         if $menu_type eq 'hidden';
    push @classes, "subset_$subset" if $subset;

    my $child = $parent->append_child('li', {
      id         => $id,
      class      => \@classes,
      inner_HTML => qq{
        <div class="controls">
          $controls
          <div class="favourite sprite fave_icon _ht" title="Favorite this track"></div>
          $help
        </div>
        <div class="track_name">$name</div>
        $desc
      }
    });

    if ($display ne 'off') {
      my $p = $child;
      do { $p->set_flag('display') } while $p = $p->parent_node; # Set a flag to indicate that this node and all its parents should be printed in the HTML
    }

    $self->{'select_all_menu'}{$node->parent_node->id} = $menu;

    $self->{'menu_count'}{$menu_class} ||= 0;
    $self->{'menu_order'}{$parent}       = $self->{'menu_count'}{$menu_class}++ unless defined $self->{'menu_order'}{$parent};

    push @{$self->{'json'}{'tracksByType'}{$menu_class}[$self->{'menu_order'}{$parent}]}, $id;
    push @{$self->{'json'}{'trackIds'}}, $id; # use an array of tracks rather than a hash so that gzip can compress the json mmore effectively.
    push @{$self->{'json'}{'tracks'}}, {  # trackIds are used to convert tracks into a hash in javascript.
      id       => $id,
      type     => $menu_class,
      name     => lc $name,
      links    => "a.$menu_class" . ($subset || $submenu_class ? ', a.' . ($subset || "$menu_class-$submenu_class") : '') . ($submenu_class ? ', a.' . "$menu_class-$submenu_class" : ''),
      renderer => $display,
      fav      => $self->{'favourite_tracks'}{$id},
      desc     => lc($desc =~ s/<[^>]+>//gr),
      html     => $child->render,
      popup    => qq{<ul class="popup_menu">$menu_header$menu</ul>},
    };
  }
}

1;
