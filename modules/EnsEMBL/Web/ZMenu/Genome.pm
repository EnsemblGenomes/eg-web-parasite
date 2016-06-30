package EnsEMBL::Web::ZMenu::Genome;

use strict;

use HTML::Entities qw(encode_entities);

use parent qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $id            = $hub->param('id');
  my $db            = $hub->param('db') || 'core';
  my $object_type   = $hub->param('ftype');
  my $db_adaptor    = $hub->database(lc($db));
  my $adaptor_name  = "get_${object_type}Adaptor";
  my $feat_adap     = $db_adaptor->$adaptor_name;

  my $features      = $feat_adap->can('fetch_all_by_hit_name')
    ? $feat_adap->fetch_all_by_hit_name($id)
      : $feat_adap->can('fetch_all_by_probeset_name')
        ? $feat_adap->fetch_all_by_probeset_name($id)
          : []
            ;

  my $external_db_id  = $features->[0] && $features->[0]->can('external_db_id') ? $features->[0]->external_db_id : '';
  my $extdbs          = $external_db_id ? $hub->species_defs->databases->{'DATABASE_CORE'}{'tables'}{'external_db'}{'entries'} : {};
  my $hit_db_name     = $extdbs->{$external_db_id}->{'db_name'} || 'External Feature';

  my $logic_name      = $features->[0] ? $features->[0]->analysis->logic_name : undef;

  $hit_db_name        = 'TRACE' if $logic_name =~ /sheep_bac_ends|BACends/; # hack to link sheep bac ends to trace archive;

  $self->caption("$id ($hit_db_name)");

## ParaSite: do not make the call to ENA to lookup the sequence - it seriously slows down the ZMenu loading time
  my $desc;
  if($hit_db_name ne 'External Feature') {
    $desc = $hit_db_name =~ /CCDS/ ? () : split("\n", $hub->get_ext_seq($hit_db_name, {'id' => $id, 'translation' => 1})->{'sequence'} || ''); # don't show EMBL desc for CCDS
  }
##

  $self->add_entry({ label => $desc }) if $desc && $desc =~ s/^>//;

  #Uniprot can't deal with versions in accessions, but the Location/Genome link needs them
  my $orig_id = $id;
  if ($hit_db_name =~ /^Uniprot/){
    $id =~ s/(\w*)\.\d+/$1/;
  }

  $self->add_entry({
    'label' => $hit_db_name eq 'TRACE' ? 'View Trace archive' : $id,
    'link'  => encode_entities($hub->get_ExtURL($hit_db_name, $id)),
    'external' => 1,
  });

  if ($logic_name and my $ext_url = $hub->get_ExtURL($logic_name, $id)) {
    $self->add_entry({
      'label' => "View in external database",
      'link'  => encode_entities($ext_url),
      'external' => 1,
    });
  }

  $self->add_entry({
    'label'   => 'View all hits',
    'link'    => $hub->url({
      'type'    => 'Location',
      'action'  => 'Genome',
      'ftype'   => $object_type,
      'id'      => $orig_id,
      'db'      => $db,
      '__clear' => 1
    })
  });

  # Eagle change, add in extra_data if available ( dna_align_feature.external_data )
  my %extra_data = $features->[0]->extra_data && ref $features->[0]->extra_data eq 'HASH' ? %{$features->[0]->extra_data} : ();

  foreach my $type ( sort keys %extra_data ) {
    $self->add_entry({
      'type'  => $type,
      'label' => $extra_data{$type}
    });
  }
}

1;
