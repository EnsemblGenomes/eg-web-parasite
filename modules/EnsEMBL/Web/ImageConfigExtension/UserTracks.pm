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
  my ($self, $menu_name, $url, $args) = @_;
  my $existing_menu = $args->{'menu'};
  my $force_hide    = $args->{'hide'};
  my $code          = $args->{'code'};
  my $hub           = $self->hub;

  ## Check if this trackhub is already attached - now that we can attach hubs via
  ## URL, they may not be saved in the imageconfig
  my $already_attached = $self->get_node($menu_name);
  ## ParaSite: we need to attach tracks by default - standard Ensembl method doesn't work here as it appears the track is already attached
  return ($menu_name, {}) if ($self->{'_attached_trackhubs'}{$url});
  ##

  ## Warning for users who attached trackhubs before the redesign
  ## Default is to show the message, since it won't do any harm
  my $is_old = 1;
  my $record;
  if ($hub->species_defs->FIRST_RELEASE_VERSION && $hub->species_defs->FIRST_RELEASE_VERSION > 99) {
    ## This is a site released after spring 2020, e.g. rapid.ensembl.org
    $is_old = 0;
  }
  elsif ($code) {
    (my $short_code = $code) =~ s/^url_//;
    foreach my $m (grep $_, $hub->user, $hub->session) {
      $record = $m->get_record_data({'type' => 'url', 'code' => $short_code});
      if ($record && $record->{'timestamp'}) {
        ## Release timestamp - 12 noon, 11/9/19
        if ($record->{'timestamp'} > 1568203200) {
          $is_old = 0;
        }
        else {
          ## Update the record so the user doesn't see this again
          $record->{'timestamp'} = time();
          $m->set_record_data($record);
        }
        last;
      }
    }
  }
  elsif ($force_hide) {
    ## Don't warn for internal trackhubs as they're off by default 
    $is_old = 0;
  }

  # Forcing it to stop showing the message.
  if ($is_old && 0) {
    ## Warn user that we are reattaching the trackhub
    $hub->session->set_record_data({
      'type'      => 'message',
      'function'  => '_warning',
      'code'      => 'th_reattachment',
      'message'   => "We have changed our trackhub interface to make it easier to configure tracks, so your old configuration may have been lost.",
    });
  }

  ## Note: no need to validate assembly at this point, as this will have been done
  ## by the attachment interface - otherwise we run into issues with synonyms
  my $trackhub  = EnsEMBL::Web::Utils::TrackHub->new('hub' => $self->hub, 'url' => $url);
  my $hub_info = $trackhub->get_hub({'parse_tracks' => 1, 'make_tree' => 1}); ## Do we have data for this species?
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
    foreach my $assembly_var (qw(UCSC_GOLDEN_PATH ASSEMBLY_VERSION ASSEMBLY_NAME)) {
      my $assembly = $self->hub->species_defs->get_config($self->species, $assembly_var);
      next unless $assembly;
      push @$assemblies,$assembly;
    }
    foreach my $assembly (@$assemblies) {
      $node = $hub_info->{'genomes'}{$assembly}{'tree'};
      $node = $node->root if $node;
      last if $node;
    }
    if ($node) {
      $self->_add_trackhub_node($node, $menu, {'name' => $menu_name, 'hide' => $force_hide, 'code' => $code});

      $self->{'_attached_trackhubs'}{$url} = 1;
    } else {
      my $assembly = $self->hub->species_defs->get_config($self->species, 'ASSEMBLY_VERSION') || $self->hub->species_defs->get_config($self->species, 'ASSEMBLY_NAME');
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
  my ($self, $parent, $tracksets, $config, $args) = @_;
  my $hub   = $self->hub;
  my $menu  = $args->{'menu'};
  my $name  = $args->{'name'};
  my $code  = $args->{'code'};

  my $do_matrix = ($config->{'dimensions'}{'x'} && $config->{'dimensions'}{'y'}) ? 1 : 0;
  $menu->set_data('has_matrix', 1) if $do_matrix;
  my $count_visible = 0;
  my $default_trackhub_tracks = {};

  foreach my $set (@{$tracksets||[]}) {
    my %tracks;
    my $submenu;

    my %options = (
      menu_key      => $name,
      menu_name     => $name,
      trackhub      => 1,
    );

    ## Skip this section for one-file track hubs, as they don't have parents or submenus 
    if (scalar keys %{$parent->data||{}}) {
      my $data      = $parent->data;

      $options{'submenu_key'}   = clean_id("${name}_$data->{'track'}", '\W'); 
      $options{'submenu_name'}  = strip_HTML($data->{'shortLabel'});
      $options{'submenu_desc'}  = $data->{'longLabel'};

      if ($do_matrix) {
        $options{'matrix_url'} = $hub->url('Config', { 
                                                      'matrix'      => 'TrackHubMatrix', 
                                                      'menu'        => $options{'submenu_key'},
                                                      'th_species'  => $hub->species,
                                  });
      }
    }
    ## Check if this submenu already exists (quite possible for trackhubs)
    $submenu = $options{'submenu_key'} ? $self->get_node($options{'submenu_key'}) : undef;
    unless ($submenu) { 
      my %matrix_params = ();
      if ($do_matrix) {
        $matrix_params{'menu'}  = 'matrix';
        $matrix_params{'url'}   = $options{'matrix_url'}; 
        ## Build metadata for matrix structure
        ## Do dimensions first as they're fiddly!
        my $dimensions = $config->{'dimensions'};
        my $dim_lookup = {};
        while (my($k, $v) = each (%{$dimensions||{}})) {
          $matrix_params{'dimensions'}{$k} = {'key' => $v};
          $dim_lookup->{$v} = $k;
        }
        $matrix_params{'dimLookup'} = $dim_lookup;
        ## Get dimension info from overall config, as parent may be an intermediate track
        while (my ($k, $v) = each (%$config)) {
          if ($k =~ /subGroup/) {
            my $k1 = $v->{'name'};
            next unless $dim_lookup->{$k1};
            while (my ($k2, $v2) = each (%{$v||{}})) {
              if ($k2 eq 'label') {
                $matrix_params{'dimensions'}{$dim_lookup->{$k1}}{'label'} = $v2;
              }
              elsif ($k2 ne 'name') {
                $matrix_params{'dimensions'}{$dim_lookup->{$k1}}{'values'}{$k2} = $v2;
              }
            }
          }
        }
        while (my ($k, $v) = each (%{$parent->data})) {
          if ($k eq 'shortLabel') {
            $matrix_params{$k} = $v;
          }
        }
        ## Save this key against the user record, so we can delete the data from localStorage later
        if ($code) {
          my ($manager, $record);
          (my $short_code = $code) =~ s/^url_//;
          foreach my $m (grep $_, $hub->user, $hub->session) {
            $record = $m->get_record_data({'type' => 'url', 'code' => $short_code});
            $manager = $m;
            if ($record && keys %$record && !$record->{'cache_ids'}{$options{'submenu_key'}}) {
              $record->{'cache_ids'}{$options{'submenu_key'}} = 1;
              $manager->set_record_data($record);
              last;
            }
          }
        }
      }
      $submenu = $self->create_menu_node($options{'submenu_key'}, $options{'submenu_name'}, {
        external    => 1,
        description => $options{'submenu_desc'},
        %matrix_params,
      });

      $menu->append_child($submenu, $options{'submenu_key'});
    }

    ## Set up sections within supertracks (applies mainly to composite tracks)
    my $subsection;
    if ($set->{'submenu_key'}) {
      my $key   = clean_id("${name}_$set->{'submenu_key'}", '\W');
      my $name  = strip_HTML($set->{'submenu_name'});
      $subsection = $self->get_node($key);
      unless ($subsection) {
        $subsection = $self->create_menu_node($key, $name, {'external' => 1}); 
        $submenu->append_child($subsection, $key);
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
      ## ParaSite: change the way we display the labels
      (my $source_name = $track->{'longLabel'}) =~ s/_/ /g;
      ## 
      my $name = 'trackhub_' . $options{'submenu_key'} . '_' . $track->{'track'};

      ## Note that we use a duplicate value in description and longLabel, because non-hub files
      ## often have much longer descriptions so we need to distinguish the two
      my $source = {
                    name            => $name,
                    source_name     => $source_name,
                    longLabel       => $track->{'longLabel'},
                    description     => $options{'submenu_key'}.': '.$track->{'longLabel'},
                    desc_url        => $track->{'description_url'},
                    signal_range    => $track->{'signal_range'},
                    link_template   => $track->{'url'},
                    link_label      => $track->{'urlLabel'},
                    };

      if ($do_matrix) {
        $source->{'subGroups'} = $track->{'subGroups'};       
      }

      # Graph range - Track Hub default is 0-127
      if (exists $track->{'viewLimits'}) {
        $source->{'viewLimits'} = $track->{'viewLimits'};
      } 
      elsif (!$track->{'autoScale'} || $track->{'autoScale'} eq 'off') {
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
      if ($track->{'visibility'}  eq 'hide' || !$track->{'visibility'}) {
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
          my $type        = ref $subtrack->{'type'} eq 'HASH' ? uc $subtrack->{'type'}{'format'} : uc $subtrack->{'type'};
          next unless ($type && $type =~ /^bigWig$/i);
          push @{$source->{'subtracks'}}, {
                                            source_name => $subtrack->{'shortLabel'},
                                            source_url  => $subtrack->{'bigDataUrl'},
                                            colour      => exists $subtrack->{'color'} ? $subtrack->{'color'} : undef,
                                          };
        }
 
        ## Set track style if appropriate
        my $default_display = 'signal';
        $options{'default_display'} = $default_display;
        if ($on_off && $on_off eq 'on') {
          $options{'display'} = $default_display;
          $count_visible++;
          # Update session records with tracks that are turned on by default
          $self->{'default_trackhub_tracks'}->{$name} = $default_display;
        }
        else {
          $options{'display'} = 'off';
        }

        $source = {%$source, %options};
        $tracks{'multiwig'}{$source->{'name'}} = $source;
      }
      else {
        ## Everything except multiWigs
        my $type = ref $track->{'type'} eq 'HASH' ? uc $track->{'type'}{'format'} : uc $track->{'type'};

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
          # Update session records with tracks that are turned on by default
          $self->{'default_trackhub_tracks'}->{$name} = $default_display;
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
