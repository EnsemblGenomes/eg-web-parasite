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

package EnsEMBL::Draw::Role::BigWig;

sub _fetch_data {
### Get the data and cache it
  my ($self, $bins, $url) = @_;
  $bins ||= $self->bins;

  #return $self->{'_cache'}{'data'} if $self->{'_cache'}{'data'};

  my $hub       = $self->{'config'}->hub;
  $url          ||= $self->my_config('url');

  if (!$url) { ## Internally configured bigwig file?
    my $dba       = $hub->database($self->my_config('type'), $self->species);

    if ($dba) {
      my $dfa = $dba->get_DataFileAdaptor();
      $dfa->global_base_path($hub->species_defs->DATAFILE_BASE_PATH);
      my ($logic_name) = @{$self->my_config('logic_names')||[]};
      my ($df) = @{$dfa->fetch_all_by_logic_name($logic_name)||[]};
      my $paths = $df->get_all_paths;
      $url = $paths->[-1];
    }
  }
  return [] unless $url;

  my $slice     = $self->{'container'};

  my $args      = { 'options' => {
                                  'hub'         => $hub,
                                  'config_type' => $self->{'config'}{'type'},
                                  'track'       => $self->{'my_config'}{'id'},
                                  },
## ParaSite: disable the concept of a default strand, unless this really isn't specified
                    'default_strand' => $self->strand || 1,
##
                    'drawn_strand' => $self->strand || 1};

  my $iow = EnsEMBL::Web::IOWrapper::Indexed::open($url, 'BigWig', $args);
  my $data;

  if ($iow) {
    ## We need to pass 'faux' metadata to the ensembl-io wrapper, because
    ## most files won't have explicit colour settings
    my $colour = $self->my_config('colour') || 'slategray';
    $self->{'my_config'}->set('axis_colour', $colour);
    $bins   ||= $self->bins;
    my $metadata = {
                    'name'            => $self->{'my_config'}->get('name'),
                    'colour'          => $colour,
                    'join_colour'     => $colour,
                    'label_colour'    => $colour,
                    'graphType'       => 'bar',
                    'unit'            => $slice->length / $bins,
                    'length'          => $slice->length,
                    'bins'            => $bins,
                    'display'         => $self->{'display'},
                    'no_titles'       => $self->my_config('no_titles'),
## ParaSite: change the default strand
                    'default_strand'  => $self->strand || 1,
##
                    'use_synonyms'    => $hub->species_defs->USE_SEQREGION_SYNONYMS,
                    };
    ## No colour defined in ImageConfig, so fall back to defaults
    unless ($colour) {
      my $colourset_key           = $self->{'my_config'}->get('colourset') || 'userdata';
      my $colourset               = $hub->species_defs->colour($colourset_key);
      my $colours                 = $colourset->{'url'} || $colourset->{'default'};
      $metadata->{'colour'}       = $colours->{'default'};
      $metadata->{'join_colour'}  = $colours->{'join'} || $colours->{'default'};
      $metadata->{'label_colour'} = $colours->{'text'} || $colours->{'default'};
    }

    ## Parse the file, filtering on the current slice
    $data = $iow->create_tracks($slice, $metadata);
  } else {
    $self->{'data'} = [];
    return $self->errorTrack(sprintf 'Could not read file %s', $self->my_config('caption'));
  }

  # Don't cache here, it's not properly managed. Rely on main cache layer.
  return $data;
}

1;
