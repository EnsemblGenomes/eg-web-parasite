package EnsEMBL::Web::ImageConfigExtension::UserTracks;

package EnsEMBL::Web::ImageConfig;

use strict;
use warnings;

sub _add_trackhub {
  my ($self, $menu_name, $url, $is_poor_name, $existing_menu, $force_hide) = @_;

  ## Check if this trackhub is already attached - now that we can attach hubs via
  ## URL, they may not be saved in the imageconfig
  my $already_attached = $self->get_node($menu_name);
## ParaSite: we need to attach tracks by default - standard Ensembl method doesn't work here as it appears the track is already attached
  return ($menu_name, {}) if ($self->{'_attached_trackhubs'}{$url});
##

  my $trackhub  = EnsEMBL::Web::File::Utils::TrackHub->new('hub' => $self->hub, 'url' => $url);
  my $hub_info = $trackhub->get_hub({'assembly_lookup' => $self->species_defs->assembly_lookup,
                                      'parse_tracks' => 1}); ## Do we have data for this species?

  if ($hub_info->{'error'}) {
    ## Probably couldn't contact the hub
    push @{$hub_info->{'error'}||[]}, '<br /><br />Please check the source URL in a web browser.';
  } else {
    my $shortLabel = $hub_info->{'details'}{'shortLabel'};
    $menu_name = $shortLabel if $shortLabel and $is_poor_name;

    my $menu     = $existing_menu || $self->tree->root->append_child($self->create_menu_node($menu_name, $menu_name, { external => 1, trackhub_menu => 1, description =>  $hub_info->{'details'}{'longLabel'}}));

    my $node;
    my $assemblies = $self->hub->species_defs->get_config($self->species,'TRACKHUB_ASSEMBLY_ALIASES');
    $assemblies ||= [];
    $assemblies = [ $assemblies ] unless ref($assemblies) eq 'ARRAY';
    foreach my $assembly_var (qw(UCSC_GOLDEN_PATH ASSEMBLY_VERSION)) {
      my $assembly = $self->hub->species_defs->get_config($self->species,$assembly_var);
      next unless $assembly;
      push @$assemblies,$assembly;
    }
    foreach my $assembly (@$assemblies) {
      $node = $hub_info->{'genomes'}{$assembly}{'tree'};
      $node = $node->root if $node;
      last if $node;
    }
    if ($node) {
      $self->_add_trackhub_node($node, $menu, $menu_name, $force_hide);

      $self->{'_attached_trackhubs'}{$url} = 1;
    } else {
      my $assembly = $self->hub->species_defs->get_config($self->species, 'ASSEMBLY_VERSION');
      $hub_info->{'error'} = ["No sources could be found for assembly $assembly. Please check the hub's genomes.txt file for supported assemblies."];
    }
  }
  return ($menu_name, $hub_info);
}

sub _add_trackhub_tracks {
  my ($self, $parent, $children, $config, $menu, $name) = @_;
  my $hub    = $self->hub;
  my $data   = $parent->data;
  my $matrix = $config->{'dimensions'}{'x'} && $config->{'dimensions'}{'y'};
  my %tracks;

  my %options = (
    menu_key     => $name,
    menu_name    => $name,
    submenu_key  => clean_id("${name}_$data->{'track'}", '\W'),
    submenu_name => $data->{'shortLabel'},
    submenu_desc => $data->{'longLabel'},
    trackhub     => 1,
  );

  if ($matrix) {
    $options{'matrix_url'} = $hub->url('Config', { 'matrix' => 1, 'menu' => $options{'submenu_key'} });

    foreach my $subgroup (keys %$config) {
      next unless $subgroup =~ /subGroup\d/;

      foreach (qw(x y)) {
        if ($config->{$subgroup}{'name'} eq $config->{'dimensions'}{$_}) {
          $options{'axis_labels'}{$_} = { %{$config->{$subgroup}} }; # Make a deep copy so that the regex below doesn't affect the subgroup config
          s/_/ /g for values %{$options{'axis_labels'}{$_}};
        }
      }

      last if scalar keys %{$options{'axis_labels'}} == 2;
    }

    $options{'axes'} = { map { $_ => $options{'axis_labels'}{$_}{'label'} } qw(x y) };
  }

  my $submenu = $self->create_menu_node($options{'submenu_key'}, $options{'submenu_name'}, {
    external => 1,
    description => $options{'submenu_desc'},
    ($matrix ? (
      menu   => 'matrix',
      url    => $options{'matrix_url'},
      matrix => {
        section     => $menu->data->{'caption'},
        header      => $options{'submenu_name'},
        desc_url    => $config->{'description_url'},
        description => $config->{'shortLabel'},
        axes        => $options{'axes'},
      }
    ) : ())
  });

  $self->alphabetise_tracks($submenu, $menu);

  my $count_visible = 0;

  my $style_mappings = {
                        'bigbed' => {
                                      'full'    => 'as_transcript_label',
                                      'pack'    => 'as_transcript_label',
                                      'squish'  => 'half_height',
                                      'dense'   => 'as_alignment_nolabel',
                                      },
                        'bigwig' => {
                                      'full'    => 'signal',
                                      'default' => 'signal',
                                      'dense'   => 'compact',
                                    },
                        'vcf' =>    {
                                      'full'    => 'histogram',
                                      'dense'   => 'compact',
                                    },
                      };

  foreach (@{$children||[]}) {
    my $track        = $_->data;
    my $type         = ref $track->{'type'} eq 'HASH' ? uc $track->{'type'}{'format'} : uc $track->{'type'};
## ParaSite: show bigGenePred as bigBed
    $type =~ s/^BIGGENEPRED$/BIGBED/;
##

    my $on_off = $config->{'on_off'} || $track->{'on_off'} || 'off';  ## ParaSite
    ## Turn track on if there's no higher setting turning it off
    if ($track->{'visibility'}  eq 'hide') {
      $on_off = 'off';
    }
## ParaSite: show the track if visibility is specified - as defined in the UCSC specification
    elsif ($track->{'visibility'} =~ /^full|pack|squish|dense$/) {
      $on_off = 'on';
    }
##
    elsif (!$config->{'on_off'} && !$track->{'on_off'}) {
      $on_off = 'on';
   }

    my $ucsc_display  = $config->{'visibility'} || $track->{'visibility'};

    ## FIXME - According to UCSC's documentation, 'squish' is more like half_height than compact
    my $squish       = $track->{'visibility'} eq 'squish' || $config->{'visibility'} eq 'squish'; # FIXME: make it inherit correctly
## ParaSite: change the way we display the labels
    (my $source_name = $track->{'longLabel'}) =~ s/_/ /g;
## 

    ## Translate between UCSC terms and Ensembl ones
    my $default_display = $style_mappings->{lc($type)}{$ucsc_display}
                              || $style_mappings->{lc($type)}{'default'}
                              || 'off';  ## ParaSite: switch off the track by default if no display is given
    $options{'default_display'} = $default_display;

    ## Set track style if appropriate 
    if ($on_off && $on_off eq 'on') {
      $options{'display'} = $default_display;
      $count_visible++;
    }
    else {
      $options{'display'} = 'off';
    }

    my $desc_url = $track->{'description_url'} ? $hub->url('Ajax', {'type' => 'fetch_html', 'url' => $track->{'description_url'}}) : '';

    ## Note that we use a duplicate value in description and longLabel, because non-hub files 
    ## often have much longer descriptions so we need to distinguish the two
    my $source       = {
      name        => $track->{'track'},
      source_name => $source_name,
      desc_url    => $track->{'description_url'},
      description => $desc_url ? qq(<span style="overflow-wrap: break-word" class="_dyna_load"><a class="hidden" href="$desc_url">$track->{'longLabel'}</a>Loading &#133;</span>) : '',
      longLabel   => $track->{'longLabel'},
      caption     => $track->{'shortLabel'},
      source_url  => $track->{'bigDataUrl'},
      colour      => exists $track->{'color'} ? $track->{'color'} : undef,
      colorByStrand => exists $track->{'colorByStrand'} ? $track->{'colorByStrand'} : undef,
      spectrum    => exists $track->{'spectrum'} ? $track->{'spectrum'} : undef,
      no_titles   => $type eq 'BIGWIG', # To improve browser speed don't display a zmenu for bigwigs
      squish      => $squish,
      signal_range => $track->{'signal_range'},
      %options
    };

    # Graph range - Track Hub default is 0-127

    if (exists $track->{'viewLimits'}) {
      $source->{'viewLimits'} = $track->{'viewLimits'};
    } elsif ($track->{'autoScale'} eq 'off') {
      $source->{'viewLimits'} = '0:127';
    }

    if (exists $track->{'maxHeightPixels'}) {
      $source->{'maxHeightPixels'} = $track->{'maxHeightPixels'};
    } elsif ($type eq 'BIGWIG' || $type eq 'BIGBED') {
## ParaSite: change height of tracks
      $source->{'maxHeightPixels'} = '60:60:60';
## ParaSite
    }

    if ($matrix) {
      my $caption = $track->{'shortLabel'};
      $source->{'section'} = $parent->data->{'shortLabel'};
      ($source->{'source_name'} = $track->{'longLabel'}) =~ s/_/ /g;
      $source->{'labelcaption'} = $caption;

      $source->{'matrix'} = {
        menu   => $options{'submenu_key'},
        column => $options{'axis_labels'}{'x'}{$track->{'subGroups'}{$config->{'dimensions'}{'x'}}},
        row    => $options{'axis_labels'}{'y'}{$track->{'subGroups'}{$config->{'dimensions'}{'y'}}},
      };

      $source->{'column_data'} = { desc_url => $config->{'description_url'}, description => $config->{'shortLabel'}, no_subtrack_description => 1 };
    }

    $tracks{$type}{$source->{'name'}} = $source;
  }
  $self->load_file_format(lc, $tracks{$_}) for keys %tracks;
}

1;
