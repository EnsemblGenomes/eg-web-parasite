package EnsEMBL::Web::Component::UserData;

sub add_file_format_dropdown {
  my ($self, $form, $limit, $js_enabled) = @_;

  my $sd              = $self->hub->species_defs;
  my @remote_formats  = $limit && $limit eq 'upload' ? () : @{$sd->multi_val('REMOTE_FILE_FORMATS')||[]};
  my @upload_formats  = $limit && $limit eq 'remote' ? () : @{$sd->multi_val('UPLOAD_FILE_FORMATS')||[]};
  my $format_info     = $sd->multi_val('DATA_FORMAT_INFO');
  my %format_type     = (map({$_ => 'remote'} @remote_formats), map({$_ => 'upload'} @upload_formats));
  ## Override defaults for datahub, which is a special case
  $format_type{'datahub'} = 'datahub';

  if (scalar @remote_formats || scalar @upload_formats) {
    my $values = [
      {'caption' => '-- Choose --', 'value' => ''},
      map { 'value' => uc($_), 'caption' => $format_info->{$_}{'label'}, $js_enabled ? ('class' => "_stt__$format_type{$_} _action_$format_type{$_}") : () }, sort (@remote_formats, @upload_formats)
    ];
    $form->add_field({
      'type'    => 'dropdown',
      'name'    => 'format',
      'label'   => 'Data format',
      'values'  => $values,
      'notes'   => '',
      $js_enabled ? ( 'class' => '_stt _action' ) : ()
    });
  }
}

1;

