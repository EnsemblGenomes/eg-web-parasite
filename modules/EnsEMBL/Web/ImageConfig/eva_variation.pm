=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfig::eva_variation;

use strict;

use parent qw(EnsEMBL::Web::ImageConfig);

sub init_cacheable {
  my $self = shift;
  
  $self->SUPER::init_cacheable(@_);
  
  my %colours;
  $colours{$_} = $self->species_defs->colour($_) for qw(variation haplotype);
  
  $self->set_parameters({
    label_width      => 100,        # width of labels on left-hand side
    opt_halfheight   => 1,          # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_empty_tracks => 0,          # include empty tracks
    colours          => \%colours,  # colour maps
    image_resizeable => 1,
    top_toolbar      => 1,
    bottom_toolbar   => 0,
  });
  
  $self->create_menus(qw(
    transcript
    variation 
    gsv_transcript
    other 
    gsv_domain
  ));
  
  $self->load_tracks;
  
  $self->get_node('transcript')->set_data('caption', 'Other genes');
  
  $self->modify_configs(
    [ 'variation', 'somatic', 'gsv_transcript', 'other' ],
    { menu => 'no' }
  );
     
  if ($self->cache_code ne $self->type) {
    my $func = "init_".$self->cache_code;
    $self->$func if $self->can($func);
  }
}

sub init_gene {
  my $self = shift;
   
  my $menu = $self->get_node('variation');
  my $options = {
    db         => 'core',
    glyphset   => '_eva',
    strand     => 'f',
    depth      => 0.5,
    bump_width => 0,
    colourset  => 'variation',
    display    => 'compact',
    renderers  => [ 'off', 'Off', 'compact', 'Collapsed' ],
  };
  $self->add_sequence_variations_default_eva('core', {}, $options);
  #$self->add_track('other', 'variation_legend', 'Variant Legend', 'variation_legend', { strand => 'r', menu => 'no' });

  $self->add_tracks('variation',
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'b', menu => 'no', tag => 0, colours => 'bisque', src => 'all'                         }]
  );
  
  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'f', menu => 'no'               }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'f', menu => 'no', notext => 1  }],
    [ 'spacer',   '', 'spacer',   { display => 'normal', strand => 'r', menu => 'no', height => 52 }],
  );
  
  $self->get_node('gsv_domain')->remove;
  
}


sub init_transcripts_top {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'f', menu => 'no', tag => 1, colours => 'bisque', src => 'all'                                        }],
  );
  
  $self->get_node($_)->remove for qw(gsv_domain transcript);
}

sub init_transcript {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'spacer',         '', 'spacer',         { display => 'normal', strand => 'r', menu => 'no', height => 10,                                             }],
  );
  
  $self->get_node('transcript')->remove;

}

sub init_transcripts_bottom {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'r', menu => 'no', tag => 1, colours => 'bisque', src => 'all'                                        }],
    [ 'ruler',            '', 'ruler',            { display => 'normal', strand => 'r', menu => 'no', notext => 1, name => 'Ruler'                                                       }],
    [ 'spacer',           '', 'spacer',           { display => 'normal', strand => 'r', menu => 'no', height => 50,                                                                      }],
  );
  
  $self->get_node($_)->remove for qw(gsv_domain transcript);
}

sub init_legend {
  my $self= shift;
  
  $self->add_tracks('other',
    [ 'variation_legend', '', 'variation_legend',     { display => 'on',  strand => 'r', menu => 'no', caption => 'Variant Legend' }], 
  );
  
  $self->get_node($_)->remove for qw(gsv_domain transcript);
  
}

1;
