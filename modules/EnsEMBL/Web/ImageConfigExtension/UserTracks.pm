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

package EnsEMBL::Web::ImageConfigExtension::UserTracks;

package EnsEMBL::Web::ImageConfig;

use strict;
use warnings;

sub _add_trackhub {
  my ($self, $menu_name, $url, $existing_menu, $force_hide) = @_;

  ## Check if this trackhub is already attached - now that we can attach hubs via
  ## URL, they may not be saved in the imageconfig
  my $already_attached = $self->get_node($menu_name);
  ## ParaSite: we need to attach tracks by default - standard Ensembl method doesn't work here as it appears the track is already attached
  return ($menu_name, {}) if ($self->{'_attached_trackhubs'}{$url});
  ##

  ## Note: no need to validate assembly at this point, as this will have been done
  ## by the attachment interface - otherwise we run into issues with synonyms
  my $trackhub  = EnsEMBL::Web::Utils::TrackHub->new('hub' => $self->hub, 'url' => $url);
  my $hub_info = $trackhub->get_hub({'parse_tracks' => 1, 'make_tree' => 1});
  $self->{'th_default_count'} = 0;

  if ($hub_info->{'error'}) {
    ## Probably couldn't contact the hub
    push @{$hub_info->{'error'}||[]}, '<br /><br />Please check the source URL in a web browser.';
  } else {
    my $description = $hub_info->{'details'}{'longLabel'};
    my $desc_url = $hub_info->{'details'}{'descriptionUrl'};
    if ($desc_url) {
      ## fix relative URLs
      if ($desc_url !~ /^http/) {
        (my $base_url = $url) =~ s/\w+\.txt$//;
        $desc_url = $base_url.$desc_url;
      }
      $description .= sprintf ' <a href="%s">More information</a>', $desc_url;
    }


    my $menu     = $existing_menu || $self->tree->root->append_child($self->create_menu_node($menu_name, $menu_name, { external => 1, trackhub_menu => 1, description =>  $description}));

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

  ## Set the default threshold to be high, so that we only warn very 'heavy' hubs
  my $threshold = $self->hub->species_defs->TRACKHUB_DEFAULT_LIMIT || 100;
  my $visible = $self->{'th_default_count'};
  if ($visible > $threshold) {
    ## Check if this warning has already been set
    my $warned = $self->hub->session->get_record_data({'type' => 'message', 'code' => 'th_threshold_warning'});
    if (!$warned) {
      $self->hub->session->set_record_data({
        'type'      => 'message',
        'function'  => '_warning',
        'code'      => 'th_threshold_warning',
        'message'   => "This trackhub has $visible tracks turned on by default. If the browser fails to load, you should click on 'Configure this page' in the sidebar and turn some of them off.",
      });
    }
  }

  return ($menu_name, $hub_info);
}

sub _add_trackhub_tracks {
  my ($self, $parent, $tracksets, $config, $menu, $name) = @_;
  my $hub       = $self->hub;
  my $data      = $parent->data;
  my $do_matrix = ($config->{'dimensions'}{'x'} && $config->{'dimensions'}{'y'}) ? 1 : 0;
  my $count_visible = 0;

  foreach my $set (@{$tracksets||[]}) {
    my %tracks;

    my %options = (
      menu_key      => $name,
      menu_name     => $name,
      submenu_key   => clean_id("${name}_$data->{'track'}", '\W'), 
      submenu_name  => strip_HTML($data->{'shortLabel'}),
      submenu_desc  => $data->{'longLabel'},
      trackhub      => 1,
    );

    if ($do_matrix) {
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

    ## Check if this submenu already exists (quite possible for trackhubs)
    my $submenu = $self->get_node($options{'submenu_key'});
    unless ($submenu) { 
      $submenu = $self->create_menu_node($options{'submenu_key'}, $options{'submenu_name'}, {
        external    => 1,
        description => $options{'submenu_desc'},
        ($do_matrix ? (
          menu   => 'matrix',
          url    => $options{'matrix_url'},
          matrix => {
            section     => $menu->data->{'caption'},
            header      => $options{'submenu_name'},
            desc_url    => $config->{'description_url'},
            description => $config->{'longLabel'},
            axes        => $options{'axes'},
          }
        ) : ())
      });

      $menu->insert_alphabetically($submenu, $options{'submenu_key'});
    }

    ## Set up sections within supertracks (applies mainly to composite tracks)
    my $subsection;
    if ($set->{'submenu_key'}) {
      my $key   = clean_id("${name}_$set->{'submenu_key'}", '\W');
      my $name  = strip_HTML($set->{'submenu_name'});
      $subsection = $self->get_node($key);
      unless ($subsection) {
        $subsection = $self->create_menu_node($key, $name, {'external' => 1}); 
        $submenu->insert_alphabetically($subsection, $key);
      }
      $options{'submenu_key'}   = $key;
      $options{'submenu_name'}  = $name;
    }

    my $style_mappings = {
                          'bam'     => {
                                        'default' => 'coverage_with_reads',
                                        },
                          'cram'    => {
                                        'default' => 'coverage_with_reads',
                                        },
                          'bigbed'  => {
                                        'full'    => 'as_transcript_nolabel',
                                        'pack'    => 'as_transcript_label',
                                        'squish'  => 'half_height',
                                        'dense'   => 'as_alignment_nolabel',
                                        'default' => 'as_transcript_label',
                                        },
                          'biggenepred' => {
                                        'full'    => 'as_transcript_nolabel',
                                        'pack'    => 'as_transcript_label',
                                        'squish'  => 'half_height',
                                        'dense'   => 'as_collapsed_label',
                                        'default' => 'as_collapsed_label',
                                        },
                          'bigwig'  => {
                                        'full'    => 'signal',
                                        'dense'   => 'compact',
                                        'default' => 'compact',
                                        },
                          'vcf'     =>  {
                                        'full'    => 'histogram',
                                        'dense'   => 'compact',
                                        'default' => 'compact',
                                        },
                        };

    my $children = $set->{'tracks'};

    foreach (@{$children||[]}) {
      my $track = $_->data;

      ## Hack for one-file trackhubs where the track name is same as the hub
      if (scalar @$children == 1) {
        $track->{'track'} = 'track_'.$track->{'track'};
      }
## ParaSite: change the way we display the labels
      (my $source_name = $track->{'longLabel'}) =~ s/_/ /g;
## 
      my $source = {
                    name            => $track->{'track'},
                    source_name     => $source_name,
                    longLabel       => $track->{'longLabel'},
                    description     => $name.': '.$track->{'longLabel'},
                    desc_url        => $track->{'description_url'},
                    signal_range    => $track->{'signal_range'},
                    };

      # Graph range - Track Hub default is 0-127
      if (exists $track->{'viewLimits'}) {
        $source->{'viewLimits'} = $track->{'viewLimits'};
      } 
      elsif ($track->{'autoScale'} eq 'off') {
        $source->{'viewLimits'} = '0:127';
      }
      else {
        $source->{'viewLimits'} = $config->{'viewLimits'};
      }

      my $type = ref $track->{'type'} eq 'HASH' ? uc $track->{'type'}{'format'} : uc $track->{'type'};
      if (exists $track->{'maxHeightPixels'}) {
        $source->{'maxHeightPixels'} = $track->{'maxHeightPixels'};
      } elsif ($type eq 'BIGWIG' || $type eq 'BIGBED') {
## ParaSite: change height of tracks
      $source->{'maxHeightPixels'} = '60:60:60';
## ParaSite
      }

      ## Is the track on or off?
      my $on_off = $config->{'on_off'} || $track->{'on_off'} || 'off'; ## Parasite
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

      ## Special settings for multiWig tracks
      if ($track->{'container'} && $track->{'container'} eq 'multiWig') {
        $source->{'no_titles'}        = 1;
        $source->{'subtracks'}        = [];

        ## Add data for each subtrack
        foreach (@{$_->child_nodes||[]}) {
          my $subtrack    = $_->data;
          $type        = ref $subtrack->{'type'} eq 'HASH' ? uc $subtrack->{'type'}{'format'} : uc $subtrack->{'type'};
          next unless ($type && $type =~ /^bigWig$/i);
          push @{$source->{'subtracks'}}, {
                                            source_name => $subtrack->{'shortLabel'},
                                            source_url  => $subtrack->{'bigDataUrl'},
                                            colour      => exists $subtrack->{'color'} ? $subtrack->{'color'} : undef,
                                          };
        }
 
        ## Set track style if appropriate
        my $default_display = 'signal';
        if ($on_off && $on_off eq 'on') {
          $options{'display'} = $default_display;
          $count_visible++;
        }
        else {
          $options{'display'} = 'off';
        }

        $source = {%$source, %options};
        $tracks{'multiwig'}{$source->{'name'}} = $source;
      }
      else {
        ## Everything except multiWigs

        ## FIXME - According to UCSC's documentation, 'squish' is more like half_height than compact
        my $ucsc_display = $config->{'visibility'} || $track->{'visibility'};
        my $squish       = $ucsc_display eq 'squish';

        ## Translate between UCSC terms and Ensembl ones
        my $default_display = $style_mappings->{lc($type)}{$ucsc_display}
                              || $style_mappings->{lc($type)}{'default'}
                              || 'off'; ## ParaSite: switch off the track by default if no display is given
        $options{'default_display'} = $default_display;

        ## Set track style if appropriate
        if ($on_off && $on_off eq 'on') {
          $options{'display'} = $default_display;
          $count_visible++;
        }
        else {
          $options{'display'} = 'off';
        }

        $source->{'source_url'}     = $track->{'bigDataUrl'};
        $source->{'colour'}         = exists $track->{'color'} ? $track->{'color'} : undef;
        $source->{'colorByStrand'}  = exists $track->{'colorByStrand'} ? $track->{'colorByStrand'} : undef;
        $source->{'spectrum'}       = exists $track->{'spectrum'} ? $track->{'spectrum'} : undef;
        $source->{'no_titles'}      = $type eq 'BIGWIG'; # To improve browser speed don't display a zmenu for bigwigs
        $source->{'squish'}         = $squish;

        if ($do_matrix) {
          my $caption = strip_HTML($track->{'shortLabel'});
          $source->{'section'} = strip_HTML($parent->data->{'shortLabel'});
          ($source->{'source_name'} = $track->{'longLabel'}) =~ s/_/ /g;
          $source->{'labelcaption'} = $caption;

          $source->{'matrix'} = {
            menu   => $options{'submenu_key'},
            column => $options{'axis_labels'}{'x'}{$track->{'subGroups'}{$config->{'dimensions'}{'x'}}},
            row    => $options{'axis_labels'}{'y'}{$track->{'subGroups'}{$config->{'dimensions'}{'y'}}},
          };
          $source->{'column_data'} = { desc_url => $config->{'description_url'}, description => $config->{'longLabel'}, no_subtrack_description => 1 };
        }

        $source = {%$source, %options};

        $tracks{$type}{$source->{'name'}} = $source;
      } ## End non-multiWig block

    } ## End loop through tracks
    $self->load_file_format(lc, $tracks{$_}) for keys %tracks;

  } ## End loop through tracksets
  $self->{'th_default_count'} += $count_visible;
}

1;
