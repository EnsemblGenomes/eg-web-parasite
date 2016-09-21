=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Info::SpeciesLanding;

use strict;

use EnsEMBL::Web::Document::HTML::HomeSearch;
use EnsEMBL::Web::DBSQL::ProductionAdaptor;
use EnsEMBL::Web::Component::GenomicAlignments;
use Data::Dumper;

use LWP::UserAgent;
use JSON;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->species;
  my $img_url      = $self->img_url;
  my $common_name  = $species_defs->SPECIES_COMMON_NAME;
  my $display_name = $species_defs->SPECIES_SCIENTIFIC_NAME;
  my $taxid        = $species_defs->TAXONOMY_ID;

  # Reduce the species name down to the main part (i.e. not including the BioProject part) - this is ParaSite specific
  my $species_image = $species;
  my @species_parts = split('_', $species);
  $species = "$species_parts[0]\_$species_parts[1]";

  my $html = '
    <div class="column-wrapper">  
      <div class="box-left">
        <div class="species-badge">';

  if(-e "$SiteDefs::ENSEMBL_SERVERROOT/eg-web-parasite/htdocs/${img_url}species/64/$species.png") {  # Check if the image exists
    $html .= qq(<img src="${img_url}species/64/$species.png" alt="" title="$display_name" />);
  }

  $html .= qq(<h1><em>$display_name</em></h1>);

  $html .= '<p class="taxon-id">';
  $html .= sprintf q{Taxonomy ID %s}, $hub->get_ExtURL_link("$taxid", 'UNIPROT_TAXONOMY', $taxid) if $taxid;
  $html .= '</p>';
  $html .= '</div>'; #species-badge

  $html .= '</div>'; #box-left
  $html .= '<div class="box-right">';

  $html .= '</div>'; # box-right
  $html .= '</div>'; # column-wrapper
  
  my $about_text = $self->_other_text('about', $species);
  if ($about_text) {
    $html .= '<div class="column-wrapper"><div class="round-box home-box">'; 
    $html .= $about_text;
    $html .= '</div>';
  }

  my (@sections);
  
  # Get a list of genome projects for this species
  my @project_list = $self->_get_projects($display_name);
  my $count = scalar(@project_list);
  my $descriptor = $count == 1 ? "is $count genome project" : "are $count genome projects";
  my $project_overview = qq(<h2>Genome Projects</h2><p>There $descriptor for <em>$display_name</em>:<ul>);
  foreach my $project (@project_list) {
    my @parts = split('_', $project);
    my $bioproject = $species_defs->get_config($project, 'SPECIES_BIOPROJECT');
    my $strain = $species_defs->get_config($project, 'SPECIES_STRAIN');
    my $project_summary = $self->_other_text('summary', $project);
    $project_summary =~ s/<h2>.*<\/h2>//; # Remove the <h2> and <p> tags
    $project_summary =~ s/<p>//;
    $project_summary =~ s/<\/p>//;
    $project_summary .= $strain ? "(Strain $strain)" : '';
    if($project_summary =~ /\w/) {
      $project_overview .= qq(<li><a href="/$project/Info/Index">$bioproject</a>: $project_summary</li>);
    } else {
      $project_overview .= qq(<li><a href="/$project/Info/Index">$bioproject</a></li>);
    }
  }
  $project_overview .= '</ul></p>';
  push(@sections, $project_overview);

  for my $section (@sections){
    $html .= sprintf(qq{<div class="round-box home-box">%s</div>}, $section);
  }
  
  $html .= '</div>';

  return $html;
}

sub _other_text {
  my ($self, $tag, $species) = @_;
  my $file = "/ssi/species/about_${species}.html";
  my $content = EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file);
  my ($other_text) = $content =~ /^.*?<!--\s*\{$tag\}\s*-->(.*)<!--\s*\{$tag\}\s*-->.*$/ms;
  #ENSEMBL-2535 strip subs
  $other_text =~ s/(\{\{sub_[^\}]*\}\})//mg;
  return $other_text;
}

sub _get_projects {
  my ($self, $species) = @_;
  my $species_defs = EnsEMBL::Web::SpeciesDefs->new();
  my @species_list = ();
  foreach ($species_defs->valid_species) {
    if ($species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME') eq $species) {
      push(@species_list, $_);
    }
  }
  return sort(@species_list);
}


1;
