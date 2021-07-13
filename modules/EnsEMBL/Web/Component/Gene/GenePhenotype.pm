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

package EnsEMBL::Web::Component::Gene::GenePhenotype;

use strict;
use Sort::Naturally;

sub gene_phenotypes {
  my $self             = shift;
  my $object           = $self->object;
  my $obj              = $object->Obj;
  my $hub              = $self->hub;
  my $species          = $hub->species_defs->SPECIES_COMMON_NAME;
  my $g_name           = $obj->stable_id;
  my $html;
  my (@rows, %list, $list_html);
  my $has_allelic = 0;  
  my $has_study   = 0;
  my %phenotypes;

  return if($obj->isa('Bio::EnsEMBL::Compara::Family'));

  # add rows from Variation DB, PhenotypeFeature
  if ($hub->database('variation')) {
    my $pfa = $hub->database('variation')->get_PhenotypeFeatureAdaptor;
    
    foreach my $pf(@{$pfa->fetch_all_by_Gene($obj)}) {
      my $phe     = $pf->phenotype->description;
      my $source  = $pf->source_name;
      my $accession_id  = $pf->get_all_ontology_accessions->[0];

      my $attribs = $pf->get_all_attributes;

      my $source_uc = uc $source;
         $source_uc =~ s/\s/_/g;
      if ($source_uc =~ /^WORMBASE_PHENOTYPE$/) {
         $source_uc = 'WORMBASE_PHENOTYPE_FULL';
      }

      my $ext_phe_url = "";
      if ($accession_id) {
	$ext_phe_url = $hub->get_ExtURL_link($phe, $source_uc, { ID => $accession_id });
      } else {
        $ext_phe_url = $phe;
      }

      my $ext_source  = $pf->external_id;
      my $ext_id  = (split '/', $pf->external_id)[-1];
      my $ext_source_url = sprintf(
        '<a href="%s">%s</a>',
        'https://www.wormbase.org'.$ext_source,
        $ext_id
      );

      my $loci_url = sprintf(
        '<a href="%s" title="%s">%s</a>',
        $hub->url({
          type    => 'Phenotype',
          action  => 'Locations',
          ph      => $pf->phenotype->dbID
        }),
        'View associate loci',
        'Other Loci'
      );

      $phenotypes{$phe} ||= { id => $pf->{'_phenotype_id'} };
      $phenotypes{$phe}{'source'}{$ext_source_url} = 1;
      $phenotypes{$phe}{'ext_url'} = $ext_phe_url;
      $phenotypes{$phe}{'loci_url'} = $loci_url;

      my $allelic_requirement = '-';
      if ($self->_inheritance($attribs)) {
        $phenotypes{$phe}{'allelic_requirement'}{$attribs->{'inheritance_type'}} = 1;
        $has_allelic = 1;
      }

      my $pmids   = '-';
      if ($pf->study) {
        $pmids = $self->add_study_links($pf->study->external_reference, $pf->study->name);
        foreach my $pmid (@$pmids) {
          $phenotypes{$phe}{'pmids'}{$pmid} = 1;
        }
        $has_study = 1;
      }
    }

    my @sorted_phes = sort { 
      my $find = 'no phenotype observed';
      my $idx1 = index($a, $find);
      my $idx2 = index($b, $find);
      ($idx1*$idx2 > 0) ? ncmp($a, $b) : $idx1 <=> $idx2;
    } keys %phenotypes;
 
    # Loop after each phenotype entry
    foreach my $phe (@sorted_phes) {
      my @pmids = keys(%{$phenotypes{$phe}{'pmids'}});
      my $study = (scalar(@pmids) != 0) ? $self->display_items_list($phenotypes{$phe}{'id'}.'pmids', 'Study links', 'Study links', \@pmids, \@pmids, 1) : '-';

      push @rows, {
        phenotype => $phenotypes{$phe}{'ext_url'},
        loci      => $phenotypes{$phe}{'loci_url'},
        source    => join(', ', keys(%{$phenotypes{$phe}{'source'}})),
        study     => $study
      };
    }
  }

  if (scalar @rows) {
    my @columns = (
      { key => 'phenotype', align => 'left', title => 'Phenotype, disease and trait' },
      { key => 'loci',    align => 'left', title => 'Associated Loci'    },
      { key => 'source',    align => 'left', title => 'Source'    }
    );

    if ($has_study == 1) {
      push @columns, { key => 'study', align => 'left', title => 'Study' , align => 'left', sort => 'html' };
    }

    if ($has_allelic == 1) {
      push @columns, { key => 'allelic', align => 'left', title => 'Allelic requirement' , help => 'Allelic status associated with the disease (monoallelic, biallelic, etc)' };
    }

    $html .= $self->new_table(\@columns, \@rows, { data_table => 'no_sort no_col_toggle', exportable => 1 })->render;
  } else {
    $html .= "<p>None found.</p>";
  }
  return $html;
}

sub add_study_links {
  my $self  = shift;
  my $pmids = shift;
  my $title = shift;
     $pmids =~ s/ //g;

  my @pmids_list;
  my $epmc_link = $self->hub->species_defs->ENSEMBL_EXTERNAL_URLS->{'EPMC_MED'};
  foreach my $pmid (split(',',$pmids)) {
    my $link = $epmc_link;
       $link =~ s/###ID###/$pmid/;
    push @pmids_list, qq{<a rel="external" href="$link">$title</a>};
  }

  return \@pmids_list;
}

1;
