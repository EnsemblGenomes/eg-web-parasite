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

package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Document::Element);
use previous qw(content);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

sub init {
  my $self          = shift;
  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my @css_groups    = @{$species_defs->get_config('ENSEMBL_JSCSS_FILES')->{'css'}||[]};

  push @css_groups,@{$species_defs->get_config('ENSEMBL_JSCSS_FILES')->{'image'}||[]};
  for (@css_groups) {
## ParaSite: do not check this condition
#    next unless $_->condition($hub);
##

    if((($hub->param('debug') || '') eq 'css' || $species_defs->ENSEMBL_DEBUG_CSS) and @{$_->files}) {
      $self->add_sheet(sprintf '/CSS?%s', $_->url_path) for @{$_->files};
    } else {
      $self->add_sheet($_->minified_url_path);
    }
  }
}

sub content {
  my $self = shift;

  my $main_css      = $self->PREV::content(@_);

  return $main_css unless $self->hub->action && $self->hub->action eq 'ExpressionAtlas' && $self->hub->gxa_status;; #adding stylesheet only for gene expression atlas view

  $main_css .=  qq{
    <link rel="stylesheet" type="text/css" href="$SiteDefs::GXA_EBI_URL/css/alt-customized-bootstrap-3.3.5.css">
  };

  return  $main_css;

}

1;
