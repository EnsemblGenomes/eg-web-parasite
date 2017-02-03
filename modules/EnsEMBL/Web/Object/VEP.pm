=head1 LICENSE

Copyright [2014-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::VEP;

use strict;
use warnings;

sub get_form_details {
  my $self = shift;

  if(!exists($self->{_form_details})) {

    # core form
    $self->{_form_details} = {
      core_type => {
        'label'   => 'Transcript database to use',
        'helptip' =>
          '<span style="font-weight: bold">Gencode basic:</span> a subset of the Ensembl transcript set; partial and other low quality transcripts are removed<br/>'.
          '<span style="font-weight: bold">RefSeq:</span> aligned transcripts from NCBI RefSeq',
        'values'  => [
          { 'value' => 'core',          'caption' => 'Ensembl transcripts'            },
          { 'value' => 'gencode_basic', 'caption' => 'Gencode basic transcripts'      },
          { 'value' => 'refseq',        'caption' => 'RefSeq transcripts'             },
          { 'value' => 'merged',        'caption' => 'Ensembl and RefSeq transcripts' }
        ],
      },

      all_refseq => {
        'label'   => 'Include additional EST and CCDS transcripts',
        'helptip' => 'The RefSeq transcript set also contains aligned EST and CCDS transcripts that are excluded by default',
      },

      # identifiers section
      symbol => {
        'label'   => 'Gene symbol',
        'helptip' => 'Report the gene symbol (e.g. HGNC)',
      },

      ccds => {
        'label'   => 'CCDS',
        'helptip' => 'Report the Consensus CDS identifier where applicable',
      },

      protein => {
        'label'   => 'Protein',
        'helptip' => 'Report the Ensembl protein identifier',
      },

      uniprot => {
        'label'   => 'UniProt',
        'helptip' => 'Report identifiers from SWISSPROT, TrEMBL and UniParc',
      },

## ParaSite: do not offer HGVS
#      hgvs => {
#        'label'   => 'HGVS',
#        'helptip' => 'Report HGVSc (coding sequence) and HGVSp (protein) notations for your variants',
#      },
##

      # frequency data
      check_existing => {
        'label'   => 'Find co-located known variants',
        'helptip' => "Report known variants from the Ensembl Variation database that are co-located with input. Use 'compare alleles' to only report co-located variants where none of the input variant's alleles are novel",
        'values'  => [
          { 'value'     => 'no',        'caption' => 'No'                              },
          { 'value'     => 'yes',       'caption' => 'Yes'                             },
          { 'value'     => 'no_allele', 'caption' => 'Yes but do not compare alleles'  }
        ]
      },

      af => {
        'label'   => '1000 Genomes global minor allele frequency',
        'helptip' => 'Report the minor allele frequency for the combined 1000 Genomes Project phase 1 population',
      },

      af_1kg => {
        'label'   => '1000 Genomes continental allele frequencies',
        'helptip' => 'Report allele frequencies for the combined 1000 Genomes Project phase 1 continental populations - AFR (African), AMR (American), EAS (East Asian), EUR (European) and SAS (South Asian)',
      },

      af_esp => {
        'label'   => 'ESP allele frequencies',
        'helptip' => 'Report allele frequencies for the NHLBI Exome Sequencing Project populations - AA (African American) and EA (European American)',
      },

      af_exac => {
        'label'   => 'ExAC allele frequencies',
        'helptip' => 'Report allele frequencies from the Exome Aggregation Consortium',
      },

      pubmed => {
        'label'   => 'PubMed IDs for citations of co-located variants',
        'helptip' => 'Report the PubMed IDs of any publications that cite this variant',
      },

      failed => {
        'label'   => 'Include flagged variants',
        'helptip' => 'The Ensembl QC pipeline flags some variants as failed; by default these are not included when searching for known variants',
      },

      biotype => {
        'label'   => 'Transcript biotype',
        'helptip' => 'Report the biotype of overlapped transcripts, e.g. protein_coding, miRNA, psuedogene',
      },

      domains => {
        'label'   => 'Protein domains',
        'helptip' => 'Report overlapping protein domains from Pfam, Prosite and InterPro',
      },

      numbers => {
        'label'   => 'Exon and intron numbers',
        'helptip' => 'For variants that fall in the exon or intron, report the exon or intron number as NUMBER / TOTAL',
      },

      tsl => {
        'label'   => 'Transcript support level',
      },

      appris => {
        'label'   => 'APPRIS',
      },

      canonical => {
        'label'   => 'Identify canonical transcripts',
      },

      sift => {
        'label'   => 'SIFT',
        'helptip' => 'Report SIFT scores and/or predictions for missense variants. SIFT is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
        'values'  => [
          { 'value'     => 'no', 'caption' => 'No'                   },
          { 'value'     => 'b',  'caption' => 'Prediction and score' },
          { 'value'     => 'p',  'caption' => 'Prediction only'      },
          { 'value'     => 's',  'caption' => 'Score only'           }
        ]
      },

      polyphen => {
        'label'   => 'PolyPhen',
        'helptip' => 'Report PolyPhen scores and/or predictions for missense variants. PolyPhen is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
        'values'  => [
          { 'value'     => 'no', 'caption' => 'No'                   },
          { 'value'     => 'b',  'caption' => 'Prediction and score' },
          { 'value'     => 'p',  'caption' => 'Prediction only'      },
          { 'value'     => 's',  'caption' => 'Score only'           }
        ]
      },

      regulatory => {
        'label'   => 'Get regulatory region consequences',
        'helptip' => 'Get consequences for variants that overlap regulatory features and transcription factor binding motifs',
        'values'  => [
          { 'value'       => 'no',   'caption' => 'No'                          },
          { 'value'       => 'reg',  'caption' => 'Yes'                         },
          { 'value'       => 'cell', 'caption' => 'Yes and limit by cell type'  }
        ]
      },

      cell_type => {
        'label'   => 'Limit to cell type(s)',
        'helptip' => 'Select one or more cell types to limit regulatory feature results to. Hold Ctrl (Windows) or Cmd (Mac) to select multiple entries.',
      },

      frequency => {
        'label'   => 'Filter by frequency',
        'helptip' => 'Exclude common variants to remove input variants that overlap with known variants that have a minor allele frequency greater than 1% in the 1000 Genomes Phase 1 combined population. Use advanced filtering to change the population, frequency threshold and other parameters',
        'values'  => [
          { 'value' => 'no',        'caption' => 'No filtering'             },
          { 'value' => 'common',    'caption' => 'Exclude common variants'  },
          { 'value' => 'advanced',  'caption' => 'Advanced filtering'       }
        ]
      },

      freq_filter => {
        'values' => [
          { 'value' => 'exclude', 'caption' => 'Exclude'      },
          { 'value' => 'include', 'caption' => 'Include only' }
        ]
      },

      freq_gt_lt => {
        'values' => [
          { 'value' => 'gt', 'caption' => 'variants with MAF greater than' },
          { 'value' => 'lt', 'caption' => 'variants with MAF less than'    },
        ]
      },

      freq_pop => {
        'values' => [
          { 'value' => '1kg_all', 'caption' => 'in 1000 genomes (1KG) combined population' },
          { 'value' => '1kg_afr', 'caption' => 'in 1KG African combined population'        },
          { 'value' => '1kg_amr', 'caption' => 'in 1KG American combined population'       },
          { 'value' => '1kg_eas', 'caption' => 'in 1KG East Asian combined population'     },
          { 'value' => '1kg_eur', 'caption' => 'in 1KG European combined population'       },
          { 'value' => '1kg_sas', 'caption' => 'in 1KG South Asian combined population'    },
          { 'value' => 'esp_aa',  'caption' => 'in ESP African-American population'        },
          { 'value' => 'esp_ea',  'caption' => 'in ESP European-American population'       },
        ],
      },

      coding_only => {
        'label'   => 'Return results for variants in coding regions only',
        'helptip' => 'Exclude results in intronic and intergenic regions',
      },

      summary => {
        'label'   => 'Restrict results',
        'helptip' => 'Restrict results by severity of consequence; note that consequence ranks are determined subjectively by Ensembl',
        'values'  => [
          { 'value' => 'no',          'caption' => 'Show all results' },
          { 'value' => 'pick',        'caption' => 'Show one selected consequence per variant'},
          { 'value' => 'pick_allele', 'caption' => 'Show one selected consequence per variant allele'},
          { 'value' => 'per_gene',    'caption' => 'Show one selected consequence per gene' },
          { 'value' => 'summary',     'caption' => 'Show only list of consequences per variant' },
          { 'value' => 'most_severe', 'caption' => 'Show most severe consequence per variant' },
        ]
      },
    };


    # add plugin stuff
    my $sd  = $self->hub->species_defs;
    if(my $pl = $sd->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG')) {

      foreach my $plugin(@{$pl->{plugins}}) {

        # each plugin form element has "plugin_" prepended to it
        $self->{_form_details}->{'plugin_'.$plugin->{key}} = {
          label => $plugin->{label} || $plugin->{key},   # plugins may not have a label
          helptip => $plugin->{helptip},
        };

        # add plugin-specific form elements
        # e.g. option selector for dbNSFP
        foreach my $form_el(@{$plugin->{form} || []}) {
          $self->{_form_details}->{'plugin_'.$plugin->{key}.'_'.$form_el->{name}} = {
            label => ($plugin->{label} || $plugin->{key}).' '.($form_el->{label} || $form_el->{name}),   # prepend label with plugin label
            helptip => $form_el->{helptip},
            values => $form_el->{values}
          };
        }
      }
    }
  }

  return $self->{_form_details};
}

1;
