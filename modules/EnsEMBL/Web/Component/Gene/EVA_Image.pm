package EnsEMBL::Web::Component::Gene::EVA_Image;

### Most code borrowed from EnsEMBL::Web::Component::VariationImage

use strict;
use LWP;
use JSON;

use base qw(EnsEMBL::Web::Component::Gene::VariationImage);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
  $self->has_image(1);
}

sub content {
  my $self        = shift;
  my $no_snps     = 1;
  my $ic_type     = 'eva_variation';
  my $hub         = $self->hub;
  my $object      = $self->object || $hub->core_object(lc($hub->param('data_type')));
  my $image_width = $self->image_width || 800;
  my $context     = $hub->param('context') || 100;
  my $extent      = $context eq 'FULL' ? 5000 : $context;
  my @confs       = qw(gene transcripts_top transcripts_bottom legend);
  my ($image_configs, $config_type, $snp_counts, $gene_object, $transcript_object, @trans);

  if ($object->isa('EnsEMBL::Web::Object::Gene') || $object->isa('EnsEMBL::Web::Object::LRG')){
    $gene_object = $object;
    $config_type = 'eva_variation';
  } else {
    $transcript_object = $object;
    $gene_object = $self->hub->core_object('gene');
    $config_type = $ic_type;
  }
  
  foreach (@confs) { 
    $image_configs->{$_} = $hub->get_imageconfig({'type' => $_ eq 'gene' ? $ic_type : $config_type, $_, 'cache_code' => $_});
    $image_configs->{$_}->set_parameters({
      image_width => $image_width, 
      context     => $context
    });
  }

  $gene_object->get_gene_slices(
    $image_configs->{'gene'},
    [ 'gene',        'normal', '33%'   ],
    [ 'transcripts', 'munged', $extent ]
  );
  
  my $transcript_slice = $gene_object->__data->{'slices'}{'transcripts'}[1]; 
  my $sub_slices       = $gene_object->__data->{'slices'}{'transcripts'}[2];  

  my @domain_logic_names = @{$self->hub->species_defs->DOMAIN_LOGIC_NAMES||[]}; 

  # Make fake transcripts
  $gene_object->store_TransformedTranscripts;                            # Stores in $transcript_object->__data->{'transformed'}{'exons'|'coding_start'|'coding_end'}
  $gene_object->store_TransformedDomains($_) for @domain_logic_names;    # Stores in $transcript_object->__data->{'transformed'}{'Pfam_hits'}

  # This is where we do the configuration of containers
  my (@transcripts, @containers_and_configs);

  # sort so trancsripts are displayed in same order as in transcript selector table  
  my $strand = $object->Obj->strand;
  @trans  = @{$gene_object->get_all_transcripts};
  my @sorted_trans;
  
  if ($strand == 1) {
    @sorted_trans = sort { $b->Obj->external_name cmp $a->Obj->external_name || $b->Obj->stable_id cmp $a->Obj->stable_id } @trans;
  } else {
    @sorted_trans = sort { $a->Obj->external_name cmp $b->Obj->external_name || $a->Obj->stable_id cmp $b->Obj->stable_id } @trans;
  } 

  foreach my $trans_obj (@sorted_trans) {
    next if $transcript_object && $trans_obj->stable_id ne $transcript_object->stable_id;
    my $image_config = $hub->get_imageconfig({type => $ic_type, cache_code => $trans_obj->stable_id});
    $image_config->init_transcript;
    
    # create config and store information on it
    $trans_obj->__data->{'transformed'}{'extent'} = $extent;
    
    $image_config->{'geneid'}      = $gene_object->stable_id;

    $image_config->{'subslices'}   = $sub_slices;
    $image_config->{'extent'}      = $extent;
    $image_config->{'_add_labels'} = 1;
    
    # Store transcript information on config
    my $transformed_slice = $trans_obj->__data->{'transformed'};

    $image_config->{'transcript'} = {
      exons        => $transformed_slice->{'exons'},
      coding_start => $transformed_slice->{'coding_start'},
      coding_end   => $transformed_slice->{'coding_end'},
      transcript   => $trans_obj->Obj,
      gene         => $gene_object->Obj
    };
     
    # Turn on track associated with this db/logic name 
    $image_config->modify_configs(
      [ $image_config->get_track_key('gsv_transcript', $gene_object) ],
      { display => 'normal', show_labels => 'off', caption => '' }
    );

    $image_config->{'transcript'}{lc($_) . '_hits'} = $transformed_slice->{lc($_) . '_hits'} for @domain_logic_names;
    $image_config->set_parameters({ container_width => $gene_object->__data->{'slices'}{'transcripts'}[3] });

    if ($gene_object->seq_region_strand < 0) {
      push @containers_and_configs, $transcript_slice, $image_config;
    } else {
      unshift @containers_and_configs, $transcript_slice, $image_config; # If forward strand we have to draw these in reverse order (as forced on -ve strand)
    }
    
    push @transcripts, { exons => $transformed_slice->{'exons'} };
  }
  
  # Tweak the configurations for the five sub images
  # Gene context block;
  my $gene_stable_id = $gene_object->stable_id;

  # Transcript block
  $image_configs->{'gene'}->{'geneid'} = $gene_stable_id; 
  $image_configs->{'gene'}->set_parameters({ container_width => $gene_object->__data->{'slices'}{'gene'}[1]->length }); 
  $image_configs->{'gene'}->modify_configs(
    [ $image_configs->{'gene'}->get_track_key('transcript', $gene_object) ],
    { display => 'transcript_nolabel', menu => 'no' }
  );
 
  # Intronless transcript top and bottom (to draw snps, ruler and exon backgrounds)
  foreach(qw(transcripts_top transcripts_bottom)) {
    $image_configs->{$_}->{'extent'}      = $extent;
    $image_configs->{$_}->{'geneid'}      = $gene_stable_id;
    $image_configs->{$_}->{'transcripts'} = \@transcripts;
    $image_configs->{$_}->{'subslices'}   = $sub_slices;
    $image_configs->{$_}->{'fakeslice'}   = 1;
    $image_configs->{$_}->set_parameters({ container_width => $gene_object->__data->{'slices'}{'transcripts'}[3] });
  }

  # Render image
  my $image = $self->new_image([
      $gene_object->__data->{'slices'}{'gene'}[1], $image_configs->{'gene'},
      $transcript_slice, $image_configs->{'transcripts_top'},
      @containers_and_configs,
      $transcript_slice, $image_configs->{'transcripts_bottom'},
      $transcript_slice, $image_configs->{'legend'},
    ],
    [ $gene_object->stable_id ]
  );
  return if $self->_export_image($image, 'no_text');

  $image->imagemap         = 'yes';
  $image->{'panel_number'} = 'top';
  $image->set_button( 'drag', 'title' => 'Drag to select region' );
  
  my $html = $image->render; 
   
  $html .= $self->_info(
    'Configuring the display',
    qq{
    <p>
      Tip: use the '<strong>Configure this page</strong>' link on the left to customise the protein domains<br />
    </p>}
  );
  
  return $html;
}

1;