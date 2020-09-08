=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

package EnsEMBL::Web::Component::Phenotype::Locations;



use strict;


## ParaSite: remove some unpopulated columns 
sub make_table {
  my $self = shift;

  my $hub = $self->hub;
  my $glossary = $hub->glossary_lookup;

  my $table = EnsEMBL::Web::NewTable::NewTable->new($self);

  my $sd = $hub->species_defs->get_config($hub->species, 'databases')->{'DATABASE_VARIATION'};

  my @exclude;
  push @exclude,'phe_desc','p_desc' if $hub->param('ph');

  my @columns = ({
    _key => 'name_id', _type => 'string no_filter',
    url_column => 'name_link',
    extra_column => 'name_extra',
    label => "Name(s)",
  },{
    _key => 'name_link', _type => 'string no_filter unshowable',
    sort_for => 'names',
  },{
    _key => 'name_extra', _type => 'string no_filter unshowable',
    sort_for => 'names',
  },{
    _key => 'feature_type', _type => 'iconic',
    label => "Type",
    width => 0.7,
    sort_for => 'feat_type',
    filter_label => 'Feature type',
    filter_keymeta_enum => 1,
    filter_sorted => 1,
    primary => 1,
  },{
    _key => 'location', _type => 'position no_filter fancy_position',
    label => 'Location',
    sort_for => 'loc',
    label => 'Genomic location (strand)',
    helptip => $glossary->{'Chr:bp'}.' The symbol (+) corresponds to the forward strand and (-) corresponds to the reverse strand.',
    width => 1.4,
  },{
    _key => 'gene_links', _type => 'string no_filter unshowable',
  },{
    _key => 'gene_titles', _type => 'string no_filter unshowable',
  },{
    _key => 'phe_desc', _type => 'iconic no_filter',
    label => 'Phenotype/Disease/Trait',
    helptip => 'Phenotype, disease or trait association',
    width => 2,
  },{
    _key => 'p_desc', _type => 'iconic unshowable',
    sort_for => 'phe_desc',
    filter_label => 'Phenotype/Disease/Trait',
    filter_keymeta_enum => 1,
    filter_sorted => 1,
    primary => 3,
  },{ 
    _key => 'phe_link', _type => 'string no_filter unshowable',
    label => 'Annotation source',
    helptip => 'Project or database reporting the association',
  },{
    _key => 'phe_source', _type => 'iconic',
    label => 'Annotation source',
    helptip => 'Project or database reporting the association',
    url_rel => 'external',
    url_column => 'phe_link',
    filter_label => 'Annotation source',
    filter_keymeta_enum => 1,
    filter_sorted => 1,
    primary => 2,
  },{
    _key => 'study_texts', _type => 'string no_filter',
    label => 'External reference',
    helptip => 'Link to the data source showing the association',
    url_column => 'study_links',
    url_rel => 'external',
    width => 0.8,
  },{
    _key => 'study_links', _type => 'string no_filter unshowable',
  },{
    _key => 'evidence_links', _type => 'string no_filter unshowable',
  });

  $table->add_columns(\@columns,\@exclude);

  $self->feature_type_classes($table);

  return $table;
}

1;

