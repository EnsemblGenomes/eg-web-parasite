=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::ToolsTable;

### Allows easy removal of items from template

use strict;

use EnsEMBL::Web::Document::Table;

use base qw(EnsEMBL::Web::Document::HTML);

sub render { 
  my $self        = shift;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $sp          = $sd->ENSEMBL_PRIMARY_SPECIES;
  my $img_url     = $sd->img_url;
  my $url;

  my $sitename = $sd->ENSEMBL_SITETYPE;
  my $html = '<h2>Processing your data</h2>';

  ## Table for online tools
  my $table = EnsEMBL::Web::Document::Table->new([
      { key => 'name',  title => 'Name',            width => '20%', align => 'left' },
      { key => 'desc',  title => 'Description',     width => '40%', align => 'left' },
      { key => 'tool',  title => 'Online tool',     width => '10%', align => 'center' },
      { key => 'limit', title => 'Upload limit',    width => '10%', align => 'center' },
      { key => 'code',  title => 'Download script', width => '10%', align => 'center' },
      { key => 'docs',  title => 'Documentation',   width => '10%', align => 'center' },
    ], [], { cellpadding => 4 }
  );

  my $tools_limit = '50MB';

  ## VEP
  if ($sd->ENSEMBL_VEP_ENABLED) {
    my $vep_link = $hub->url({'species' => $sp, qw(type Tools action VEP)});
    $table->add_row({
      'name'  => sprintf('<a href="%s" class="nodeco"><b>Variant Effect Predictor</b></a>', $vep_link),
      'desc'  => 'Analyse your own variants and predict the functional consequences of known and unknown variants via our Variant Effect Predictor (VEP) tool.',
      'limit' => $tools_limit.'*',
      'tool'  => sprintf('<a href="%s" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $vep_link, $img_url),
      'code'  => sprintf('<a href="https://github.com/Ensembl/ensembl-tools/archive/release/%s.zip" rel="external" class="nodeco"><img src="%s16/download.png" alt="Download" title="Download Perl script" /></a>', $sd->ENSEMBL_VERSION, $img_url),
      'docs'  => sprintf('<a href="/info/Tools/vep.html"><img src="%s16/info.png" alt="Documentation" /></a>', $img_url)
    });
  }

  ## BLAST
  if ($sd->ENSEMBL_BLAST_ENABLED) {
    my $link = $hub->url({'species' => $sp, qw(type Tools action Blast)});
    $table->add_row({
      'name' => sprintf('<b><a class="nodeco" href="%s">BLAST/BLAT</a></b>', $link),
      'desc' => 'Search our genomes for your DNA or protein sequence.',
      'tool' => sprintf('<a href="%s" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $link, $img_url),
      'limit' => $tools_limit,
      'code' => '',
      'docs' => sprintf('<a href="/info/Tools/blast.html" class="popup"><img src="%s16/info.png" alt="Documentation" /></a>', $img_url)
    });
  }

  my $gprofile_link = 'https://biit.cs.ut.ee/gprofiler/gost';
  ## G:Profiler
  $table->add_row({
    'name' => sprintf('<b><a class="nodeco" href="%s">g:Profiler</a></b>', $gprofile_link),
    'desc' => 'Gene set enrichment. WormBase ParaSite genomes and the results of our functional analysis annotation are processed by g:Profiler to offer gene set enrichment analysis as a service. ',
    'tool' => sprintf('<a href="%s" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $gprofile_link, $img_url),
    'limit' => '',
    'code' => '',
    'docs' => sprintf('<a href="/info/Tools/gprofiler.html" class="popup"><img src="%s16/info.png" alt="Documentation" /></a>', $img_url)
  });


  $html .= $table->render;

  $html .= '* For larger datasets we provide an API script that can be downloaded (you will also need to install our Perl API, below, to run the script).';

  ## Table of other tools

  $html .= qq(<h2 class="top-margin">Accessing $sitename data</h2>);

  $table = EnsEMBL::Web::Document::Table->new([
      { key => 'name', title => 'Name', width => '20%', align => 'left' },
      { key => 'desc', title => 'Description', width => '30%', align => 'left' },
      { key => 'from', title => 'Get it from:', width => '30%', align => 'center' },
      { key => 'docs', title => 'Documentation', width => '10%', align => 'center' },
    ], [], { cellpadding => 4 }
  );

  ## BIOMART
  if ($sd->ENSEMBL_MART_ENABLED) {
    $table->add_row({
      'name' => '<b><a href="/biomart/martview">BioMart</a></b>',
      'desc' => "Use this data-mining tool to export custom datasets from $sitename.",
      'from' => '',
      'docs' => sprintf('<a href="/info/Tools/biomart.html" class="popup"><img src="%s16/info.png" alt="Documentation" /></a>', $img_url)
    });
  }
  
  ## REST
  if (my $rest_url = $sd->ENSEMBL_REST_URL) {
    $table->add_row({
      "name" => sprintf("<b><a href=%s>Wormbase Parasite REST server</a></b>", $rest_url),
      'desc' => 'Access Wormbase Parasite using your favourite programming language',
      "tool" => sprintf("<a href='%s' class='nodeco'><img src='%s16/tool.png' alt='Tool' title='Go to online tool' /></a>", $rest_url, $img_url),
      'docs' => sprintf('<a href="%s"><img src="%s16/info.png" alt="Documentation" /></a>', '/info/Tools/rest_api.html' || $rest_url, $img_url)
    });
  }
  $html .= $table->render;

  return $html;
}

1;
