package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped) = @_;

  my $species_defs  = $self->hub->species_defs;

  my $set_order;
  my $is_pan = $self->hub->function eq 'pan_compara';
  if($is_pan){
    $set_order = [qw(all ensembl metazoa plants fungi protists bacteria archaea)];
  }


  my $categories = {};
  my $species_sets = {
    'ensembl'     => {'title' => 'Vertebrates', 'desc' => '', 'species' =>[]},
    'metazoa'     => {'title' => 'Metazoa', 'desc'=>'', 'species'=>[]},
    'plants'      => {'title' => 'Plants', 'desc' => '', 'species' => []},
    'fungi'       => {'title' => 'Fungi', 'desc' => '', 'species' => []},
    'protists'    => {'title' => 'Protists', 'desc' => '', 'species' => []},
    'bacteria'    => {'title' => 'Bacteria', 'desc' => '', 'species' => []},
    'archaea'     => {'title' => 'Archaea', 'desc' => '', 'species' => []},
    'all'       =>   {'title' => 'All', 'desc' => '', 'species' => []},
  };

  my $sets_by_species = {};

  my $spsites =  $species_defs->ENSEMBL_SPECIES_SITE();
  foreach my $species (keys %$orthologue_list) {
    next if $skipped->{$species};
    my $group = $spsites->{lc($species)};
    if($group eq 'bacteria'){
      if($self->is_archaea(lc $species)){
        $group='archaea';
      }
    }
    elsif (!$is_pan){ # not the pan compara page - generate groups
      $group = $species_defs->get_config($species, 'SPECIES_GROUP') || 'all';
      if(!exists $species_sets->{$group}){
        $species_sets->{$group} = {'title'=>ucfirst $group,'species'=>[]};
        push(@$set_order,$group);
      }
    }

    push (@{$species_sets->{'all'}{'species'}}, $species);
    my $sets = [];

    my $orthologues = $orthologue_list->{$species} || {};
    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}{$stable_id};
      my $orth_desc = $orth_info->{'homology_desc'};
      $species_sets->{'all'}{$orth_desc}++;
      $species_sets->{$group}{$orth_desc}++;
      $categories->{$orth_desc} = {key=>$orth_desc, title=>$orth_desc} unless exists $categories->{$orth_desc};
    }
    push(@{$species_sets->{$group}{'species'}},$species);
    push (@$sets, $group) if(exists $species_sets->{$group});
    $sets_by_species->{$species} = $sets;
  }

  if(!$is_pan) {
    my @unorder = @$set_order;
    @$set_order = sort(@unorder);
    unshift(@$set_order, 'all');
  }

  return ($species_sets, $sets_by_species, $set_order, $categories);
}

1;
