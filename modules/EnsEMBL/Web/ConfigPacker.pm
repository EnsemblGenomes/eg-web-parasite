=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ConfigPacker;

use LWP::UserAgent;
use HTML::Entities;
use XML::Simple;
use JSON;
use Data::Dumper;

use previous qw(munge_config_tree);

sub _munge_meta {
  my $self = shift;
  
  ##########################################
  # SPECIES_COMMON_NAME     = Human        #
  # SPECIES_PRODUCTION_NAME = homo_sapiens #
  # SPECIES_SCIENTIFIC_NAME = Homo sapiens #
  ##########################################

  my %keys = qw(
    species.taxonomy_id           TAXONOMY_ID
    species.url                   SPECIES_URL
    species.display_name          SPECIES_COMMON_NAME
    species.production_name       SPECIES_PRODUCTION_NAME
    species.scientific_name       SPECIES_SCIENTIFIC_NAME
    species.bioproject_id         SPECIES_BIOPROJECT
    assembly.accession            ASSEMBLY_ACCESSION
    assembly.web_accession_source ASSEMBLY_ACCESSION_SOURCE
    assembly.web_accession_type   ASSEMBLY_ACCESSION_TYPE
    assembly.default              ASSEMBLY_NAME
    assembly.name                 ASSEMBLY_DISPLAY_NAME
    liftover.mapping              ASSEMBLY_MAPPINGS
    genebuild.method              GENEBUILD_METHOD
    genebuild.version             GENEBUILD_VERSION
    provider.name                 PROVIDER_NAME
    provider.url                  PROVIDER_URL
    provider.logo                 PROVIDER_LOGO
    species.strain                SPECIES_STRAIN
    species.sql_name              SYSTEM_NAME
    species.biomart_dataset       BIOMART_DATASET
    species.wikipedia_url         WIKIPEDIA_URL
    ploidy                        PLOIDY
  );
  
  my @months    = qw(blank Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my $meta_info = $self->_meta_info('DATABASE_CORE') || {};
  my @sp_count  = grep { $_ > 0 } keys %$meta_info;

  ## How many species in database?
  $self->tree->{'SPP_IN_DB'} = scalar @sp_count;
    
  if (scalar @sp_count > 1) {
    if ($meta_info->{0}{'species.group'}) {
      $self->tree->{'DISPLAY_NAME'} = $meta_info->{0}{'species.group'};
    } else {
      (my $group_name = $self->{'_species'}) =~ s/_collection//;
      $self->tree->{'DISPLAY_NAME'} = $group_name;
    }
  } else {
    $self->tree->{'DISPLAY_NAME'} = $meta_info->{1}{'species.display_name'}[0];
  }

## EG
  my $metadata_db = $self->full_tree->{MULTI}->{databases}->{DATABASE_METADATA};
  my $genome_info_adaptor;
  if ($metadata_db) {
    my $dbc = Bio::EnsEMBL::DBSQL::DBConnection->new(
      -USER   => $metadata_db->{USER},
      -PASS   => $metadata_db->{PASS},
      -PORT   => $metadata_db->{PORT},
      -HOST   => $metadata_db->{HOST},
      -DBNAME => $metadata_db->{NAME}
    );
    $genome_info_adaptor = Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor->new(-DBC => $dbc);
  }
##

  while (my ($species_id, $meta_hash) = each (%$meta_info)) {
    next unless $species_id && $meta_hash && ref($meta_hash) eq 'HASH';
    
    my $species  = ucfirst $meta_hash->{'species.production_name'}[0];
    my $bio_name = $meta_hash->{'species.scientific_name'}[0];
    
    ## Put other meta info into variables
    while (my ($meta_key, $key) = each (%keys)) {
      next unless $meta_hash->{$meta_key};
      
      my $value = scalar @{$meta_hash->{$meta_key}} > 1 ? $meta_hash->{$meta_key} : $meta_hash->{$meta_key}[0]; 
      $self->tree->{$species}{$key} = $value;
    }

    ## Do species group
    my $taxonomy = $meta_hash->{'species.classification'};

    if ($taxonomy && scalar(@$taxonomy)) {
      my %valid_taxa = map {$_ => 1} @{ $self->tree->{'TAXON_ORDER'} };
      my @matched_groups = grep {$valid_taxa{$_}} @$taxonomy;
      $self->tree($species)->{'SPECIES_GROUP_HIERARCHY'} = \@matched_groups;
    }

    ## ParaSite changes to include nematode clade in the classification
    unshift @{$taxonomy}, "Clade@{$meta_hash->{'species.nematode_clade'}}[0]";
    ## End ParaSite changes

    ## ParaSite changes to force alternative names into an array
    $self->tree->{$species}{'SPECIES_ALTERNATIVE_NAME'} = $meta_hash->{'species.alternative_name'} if $meta_hash->{'species.alternative_name'};
    ## End ParaSite changes
   
    if ($taxonomy && scalar(@$taxonomy)) {
      my $order = $self->tree->{'TAXON_ORDER'};
      
      foreach my $taxon (@$taxonomy) {
        foreach my $group (@$order) {
          ## ParaSite changes to allow sub-grouping of taxonomy on homepage
          my $sub_order = $self->tree->{'TAXON_SUB_ORDER'}->{$group} || ['parent'];
          foreach my $subgroup (@$sub_order) {
            my $sub_sub_order = $self->tree->{'TAXON_MULTI'}->{$subgroup} || [$subgroup];
            foreach my $subsubgroup (@$sub_sub_order) {
              if ($taxon eq $subsubgroup) {
                $self->tree->{$species}{'SPECIES_SUBGROUP'} = $subsubgroup;
                last;
              }
            }
          }
          ## End ParaSite changes
          if ($taxon eq $group) {
            $self->tree->{$species}{'SPECIES_GROUP'} = $group;
            last;
          }
        }
        
        last if $self->tree->{$species}{'SPECIES_GROUP'};
      }
    }

    ## create lookup hash for species aliases
    foreach my $alias (@{$meta_hash->{'species.alias'}}) {
      $self->full_tree->{'MULTI'}{'SPECIES_ALIASES'}{$alias} = $species;
    }

    ## Backwards compatibility
    $self->tree->{$species}{'SPECIES_BIO_NAME'}  = $bio_name;
    ## Used mainly in <head> links
    ($self->tree->{$species}{'SPECIES_BIO_SHORT'} = $bio_name) =~ s/^([A-Z])[a-z]+_([a-z]+)$/$1.$2/;
    
    if ($self->tree->{'ENSEMBL_SPECIES'}) {
      push @{$self->tree->{'DB_SPECIES'}}, $species;
    } else {
      $self->tree->{'DB_SPECIES'} = [ $species ];
    }

    
    $self->tree->{$species}{'SPECIES_META_ID'} = $species_id;

    ## Munge genebuild info
    my @A = split '-', $meta_hash->{'genebuild.start_date'}[0];
    
    $self->tree->{$species}{'GENEBUILD_START'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    $self->tree->{$species}{'GENEBUILD_BY'}    = $A[2];

    @A = split '-', $meta_hash->{'genebuild.initial_release_date'}[0];
    
    $self->tree->{$species}{'GENEBUILD_RELEASE'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    
    @A = split '-', $meta_hash->{'genebuild.last_geneset_update'}[0];

    $self->tree->{$species}{'GENEBUILD_LATEST'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    
    @A = split '-', $meta_hash->{'assembly.date'}[0];
    
    $self->tree->{$species}{'ASSEMBLY_DATE'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    

    $self->tree->{$species}{'HAVANA_DATAFREEZE_DATE'} = $meta_hash->{'genebuild.havana_datafreeze_date'}[0];

    # check if there are sample search entries defined in meta table ( the case with Ensembl Genomes)
    # they can be overwritten at a later stage  via INI files
    my @ks = grep { /^sample\./ } keys %{$meta_hash || {}}; 
    my $shash;

    foreach my $k (@ks) {
      (my $k1 = $k) =~ s/^sample\.//;
      $shash->{uc $k1} = $meta_hash->{$k}->[0];
    }
    ## add in any missing values where text omitted because same as param
    while (my ($key, $value) = each (%$shash)) {
      next unless $key =~ /PARAM/;
      (my $type = $key) =~ s/_PARAM//;
      unless ($shash->{$type.'_TEXT'}) {
        $shash->{$type.'_TEXT'} = $value;
      } 
    }

    $self->tree->{$species}{'SAMPLE_DATA'} = $shash if scalar keys %$shash;

    # check if the karyotype/list of toplevel regions ( normally chroosomes) is defined in meta table
    @{$self->tree($species)->{'TOPLEVEL_REGIONS'}} = @{$meta_hash->{'regions.toplevel'}} if $meta_hash->{'regions.toplevel'};
   
    (my $group_name = $self->{'_species'}) =~ s/_collection//;
    $self->tree($species)->{'SPECIES_DATASET'} = $group_name;
 
    # convenience flag to determine if species is polyploidy
    $self->tree->{$species}{POLYPLOIDY} = ($self->tree->{$species}{PLOIDY} > 2);

## EG - munge EG genome info 
    if ($genome_info_adaptor) {
      my $dbname = $self->tree->{databases}->{DATABASE_CORE}->{NAME};
      foreach my $genome (@{ $genome_info_adaptor->fetch_all_by_dbname($dbname) }) {
        my $species = $genome->species;
        $self->tree($species)->{'SEROTYPE'}     = $genome->serotype;
        $self->tree($species)->{'PUBLICATIONS'} = $genome->publications;
      }
    }
##  

## ParaSite: get the tracks from EVA
    $self->tree($species)->{'EVA_TRACKS'} = $self->get_EVA_tracks($species);
##

  }

  $genome_info_adaptor->{dbc}->db_handle->disconnect if $genome_info_adaptor; # EG - hacky, but seems to be needed
}

sub get_EVA_tracks {
  my ($self, $species) = @_;
  
  my $assembly_info = $self->eva_api(sprintf("%s/webservices/rest/v1/meta/species/list", $SiteDefs::EVA_URL));
  my $eva_species;
  my $eva_assembly;
  foreach my $result_set (@{$assembly_info->{response}}) {
    if($result_set->{numResults} == 0) {
      next;
    }
    foreach my $dataset (@{$result_set->{result}}) {
      if($dataset->{assemblyAccession} eq $self->tree->{$species}{'ASSEMBLY_ACCESSION'}) {
        $eva_species = ucfirst($dataset->{taxonomyEvaName});
        $eva_assembly = sprintf('%s_%s', $dataset->{taxonomyCode}, $dataset->{assemblyCode});
      }
    }
  }  
  return unless $eva_species && $eva_assembly;

  my $data_structure = $self->eva_api(sprintf("%s/webservices/rest/v1/meta/studies/all?browserType=sgv&species=%s", $SiteDefs::EVA_URL, $eva_species));
  
  my $track_list = [];
  foreach my $result_set (@{$data_structure->{response}}) {
    if($result_set->{numResults} == 0) {
      next;
    }
    foreach my $dataset (@{$result_set->{result}}) {
      my $ena_url = sprintf("http://www.ebi.ac.uk/ena/data/view/%s&display=xml", $dataset->{id});
      my $ua = LWP::UserAgent->new();
      my $response = $ua->get($ena_url);
      my $description;
      if ($response->is_success) {
        my $result = XMLin($response->decoded_content);
        my $submitter = $result->{PROJECT}{center_name};
        my $name = $result->{PROJECT}->{NAME};
        my $formatted;
        if($result->{PROJECT}->{DESCRIPTION}) {
          $formatted = encode_entities($result->{PROJECT}->{DESCRIPTION});
        } elsif($result->{STUDY}->{DESCRIPTOR}->{STUDY_DESCRIPTION}) {
          $formatted = encode_entities($result->{STUDY}->{DESCRIPTOR}->{STUDY_DESCRIPTION});
        }
        $description = qq(<h3>Study Overview</h3><p><b>Study Name:</b> $name<br /><b>Submitter:</b> $submitter<br /><b>Project Description:</b> $formatted<br /><i>Description provided by <a href="http://www.ebi.ac.uk/ena">ENA</a></i></p>);
      }
      my $track = {
        'name'        => $dataset->{name},
        'study_id'    => $dataset->{id},
        'description' => $description,
        'eva_species' => $eva_assembly
      };
      push(@$track_list, $track);
    }
  }
  
  return $track_list;
    
}

sub eva_api {
  my ($self, $url) = @_;
  
  my $uri = URI->new($url);
  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new();
    $ua->agent('WormBase ParaSite (EMBL-EBI) Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->timeout(10);
    $self->{user_agent} = $ua;
  }
  
  my $response = $self->{user_agent}->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;
  
  if ($response->is_error) {
    warn 'Error loading EVA data: ' . $response->status_line;
    return;
  }
  
  return from_json($content); 
}

1;
