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
use File::Slurp;
use Text::MultiMarkdown qw(markdown);

sub content {
  my $self = shift;
  my $hub  = $self->hub;
  my $ph_id              = $hub->param('ph');
  my $ontology_accession = $hub->param('oa');
  my $error;

  if (!$ph_id && !$ontology_accession) {
    return $self->_warning("Parameter missing!", "The URL should contain the parameter 'oa' or 'ph'");
  }

  my $html;
  my $table = $self->make_table();
  my $pa =  $hub->database('variation')->get_PhenotypeAdaptor;
  my $ph_stable_id = $pa->fetch_by_dbID($ph_id)->name; #No stable_id API for the object, waiting until E! 103
  
  #ParaSite: reading PS description from parasite-static
  my $file = $SiteDefs::ENSEMBL_SERVERROOT."/parasite-static/phenotype/$ph_stable_id.md"; 
  if (-e $file) {
    my $text = read_file($file);
    $text =~ s/#.*\R//;
    my $phenotypeDesc = markdown($text);
    $html .= '<p>'.$phenotypeDesc.'</p>';
  } else {
    warn "The file $file does not exist"; 
  }

  $html .= $table->render($hub,$self);
  return $html;
}

sub table_content {
  my ($self,$callback) = @_;

  my $hub = $self->hub;

  my $ph_id              = $hub->param('ph');
  my $ontology_accession = $hub->param('oa');
 
  my $gene_ad = $hub->database('core')->get_adaptor('Gene');
  my $pf_ad   = $hub->database('variation')->get_adaptor('PhenotypeFeature');

  my (%gene_ids,$pfs);

  if ($ph_id) {
    $pfs = $pf_ad->fetch_all_by_phenotype_id_source_name($ph_id);
  }
  else {
    $pfs = $pf_ad->fetch_all_by_phenotype_accession_source($ontology_accession);
  }

  ROWS: foreach my $pf (@{$pfs}) {
    next if $callback->free_wheel();

    unless($callback->phase eq 'outline') {
      
      my $feat_type = $pf->type;
        
      next if ($feat_type eq 'SupportingStructuralVariation');

      if ($feat_type eq 'Variation') {
        $feat_type = 'Variant';
      } elsif ($feat_type eq 'StructuralVariation') {
        $feat_type = 'Structural Variant';
      }

      my $pf_name      = $pf->object_id;
      my $region       = $pf->seq_region_name;
      my $start        = $pf->seq_region_start;
      my $end          = $pf->seq_region_end;
      my $strand       = $pf->seq_region_strand;
      my $strand_label = ($strand == 1) ? '+' : '-';
      my $phe_desc     = $pf->phenotype_description; 
      my $study_xref   = ($pf->study) ? $pf->study->external_reference : undef;
      my $study_title  = ($pf->study) ? $pf->study->name : undef;
      my $external_id  = ($pf->external_id) ? $pf->external_id : undef;
      my $attribs      = $pf->get_all_attributes;
      my $source       = $pf->source_name;  
      my ($source_text,$source_url) = $self->source_url($pf_name, $source, $external_id, $attribs, $pf);

      my @reported_genes = split(/,/,$pf->associated_gene);

      my @assoc_genes;
      # preparing the URL for all the associated genes and ignoring duplicate one
      foreach my $id (@reported_genes) {
        $id =~ s/\s//g;
        next if $id =~ /intergenic|pseudogene/i || $id eq 'NR';
      
        my $gene_label = [$id,undef,undef];

        if (!$gene_ids{$id}) {
          foreach my $gene (@{$gene_ad->fetch_all_by_external_name($id) || []}) {
            $gene_ids{$id} = $gene->description;
          }
        }

        if ($gene_ids{$id}) {
          $gene_label = [$id,$hub->url({ type => 'Gene', action => 'Summary', g => $id }),$gene_ids{$id}];
        }
        push @assoc_genes,$gene_label;
      }

      my $studies = $self->study_urls($study_xref, $study_title);
      my ($name_id,$name_url,$name_extra) = $self->pf_link($pf,$pf->type,$pf->phenotype_id);

      # ClinVar specific data
      my $evidence_list;
      my $submitter_list = [];
      if ($source =~ /clinvar/i) {
        if ($attribs->{'MIM'}) {
          my @data = split(',',$attribs->{'MIM'});
          foreach my $ext_ref (@data) {
            push(@$studies, [$hub->get_ExtURL('OMIM', $ext_ref),'MIM:'.$ext_ref]);
          }
        }
        if ($attribs->{'pubmed_id'}) {
          my @data = split(',',$attribs->{'pubmed_id'});
          $evidence_list = $self->supporting_evidence_link(\@data, 'pubmed_id');
        }
        # Submitter data
        $submitter_list = $pf->submitter_names;
      }
 
      my @study_links    = map { $_->[0]||'' } @$studies;
      my @study_texts    = map { $_->[1]||'' } @$studies;
      my @evidence_texts = ($evidence_list) ? keys(%$evidence_list) : ();
      my @evidence_links = ($evidence_list) ? map { $evidence_list->{$_} } @evidence_texts : ();
      my @gene_texts     = map { $_->[0]||'' } @assoc_genes;
      my @gene_links     = map { $_->[1]||'' } @assoc_genes;
      my @gene_titles    = map { $_->[2]||'' } @assoc_genes;


      my $row = {
           name_id          => $name_id,
           name_link        => $name_url,
           name_extra       => $name_extra,
           location         => "$region:$start-$end$strand_label",
           feature_type     => $feat_type,
           phe_source       => $source_text,
           phe_link         => $source_url,
           study_links      => join("\r",'',@study_links),
           study_texts      => join("\r",'',@study_texts),
           study_submitter  => join(', ', $submitter_list ? @$submitter_list : ()),
           evidence_links   => join("\r",'',@evidence_links),
           evidence_texts   => join("\r",'',@evidence_texts),
           gene_links       => join("\r",'',@gene_links),
           gene_texts       => join("\r",'',@gene_texts),
           gene_titles      => join("\r",'',@gene_titles),
      };

      if (!$hub->param('ph')) {
        $row->{phe_desc} = $self->phenotype_url($phe_desc,$pf->phenotype_id);
        $row->{p_desc}   = $phe_desc;
      }

      $callback->add_row($row);
      last ROWS if $callback->stand_down;
    }
  }
}


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

sub study_urls {
  my ($self, $pmid, $title) = @_;
  my $link;
  my @links;
  $link = $self->hub->species_defs->ENSEMBL_EXTERNAL_URLS->{'EPMC_MED'};
  $link =~ s/###ID###/$pmid/;
  push @links,[$link, $title];
  
  return \@links;
}


1;

