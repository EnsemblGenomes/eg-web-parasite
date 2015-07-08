=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Ontology;

sub ontology_table {
  my ($self, $chart) = @_;

  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $oid          = $hub->param('oid');
  my $go           = $hub->param('go');

  my $html = '';    #<p><h3>The following ontology terms have been annotated to this entry:</h3></p>';

  my $columns = [{key => 'ancestor_chart', title => 'Chart', width => '5%', align => 'centre'}, {key => 'go', title => 'Accession', width => '5%', align => 'left'}, {key => 'description', title => 'Term', width => '20%', align => 'left'}, {key => 'evidence', title => 'Evidence', width => '3%', align => 'center'}, {key => 'source', title => 'Annotation Source', width => '24%', align => 'center'},];

  my %clusters = $species_defs->multiX('ONTOLOGIES');

  my $olink = $clusters{$oid}->{db};

  if (my $settings = EnsEMBL::Web::Constants::ONTOLOGY_SETTINGS->{$olink}) {
    if ($settings->{url}) {
      $olink = sprintf qq{<a href="%s">%s</a>}, $settings->{url}, $settings->{name} || $olink;
    }
    else {
      $olink = $settings->{name} if ($settings->{name});
    }
  }

  my $go_database = $self->hub->get_databases('go')->{'go'};
  my @terms = grep {$chart->{$_}->{selected}} keys %$chart;
  if ($clusters{$oid}->{db} eq 'GO') {

    # In case of GO ontology try and get GO slim terms
    foreach (@terms) {
      my $query = qq(        
           SELECT t.accession, t.name,c.distance
           FROM closure c join term t on c.parent_term_id= t.term_id
           where child_term_id = (SELECT term_id FROM term where accession='$_')
           and parent_term_id in (SELECT term_id FROM term t where subsets like '%goslim_generic%')
           order by distance         
           );
      my $result = $go_database->dbc->db_handle->selectall_arrayref($query);
      foreach my $r (@$result) {
        my ($accession, $name, $distance) = @{$r};
        $chart->{$_}->{goslim}->{$accession}->{'name'}     = $name;
        $chart->{$_}->{goslim}->{$accession}->{'distance'} = $distance;
      }
    }
  }
  $html .= sprintf qq{<h3>The following terms describe the <i>%s</i> of this entry in %s</h3>}, $clusters{$oid}->{description}, $olink;

  my $table = $self->new_table(
    $columns,
    [],
    {
      code              => 1,
      data_table        => 1,
      id                => 'ont_table',
      toggleable        => 0,
      class             => '',
      data_table_config => {iDisplayLength => 10}
    },
  );

  $self->process_data($table, $chart, $clusters{$oid}->{db}, $oid);
  $html .= $table->render;

  return '<p>No ontology terms have been annotated to this entity.</p>' unless @terms;
  return $html;
}

1;

