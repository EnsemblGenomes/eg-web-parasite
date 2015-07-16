=head1 LICENSE

Copyright [2009-2015] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Info::SpeciesBurp;

sub content {
  my $self           = shift;
  my %error_messages = EnsEMBL::Web::Constants::ERROR_MESSAGES;
  my $error_text     = $error_messages{$self->hub->function};

  ## ParaSite: are we looking for one of the non-ParaSite species (i.e. links out from BioMart in Ensembl format)
  my $hub = $self->hub;
  my $error_url = $ENV{'REDIRECT_URL'};
  my @url_parts = split(/\//, $error_url);
  my $species = $url_parts[1];
  my $division = $hub->species_defs->ENSEMBL_SPECIES_SITE->{lc($species)};
  my $query = $ENV{'REDIRECT_QUERY_STRING'};
  my %params = map({split(/=/, $_)} split(/&/, $query));
  my $stable_id = $params{'g'};
  if($division && $stable_id) {
    my $url;
    if(grep(/$division/, qw/ensembl metazoa plants fungi protists bacteria/) || $division eq $hub->species_defs->GENOMIC_UNIT) {
      $url = $hub->url({
        species => $species,
	type    => 'Gene',
        action  => 'Summary',
        g       => $stable_id,
        __clear => 1
      });
    } else {
      $url  = $hub->get_ExtURL(uc "$division\_gene", {'SPECIES'=>$species, 'ID'=>$stable_id});
    }
  return $hub->redirect($url);
  } elsif ($division) {
    my $url;
    if(grep(/$division/, qw/ensembl metazoa plants fungi protists bacteria/) || $division eq $hub->species_defs->GENOMIC_UNIT) {
      $url = $hub->url({
        species => $species,
        type    => 'Info',
        action  => 'Index',
        __clear => 1
      });
    } else {
      $url  = $hub->get_ExtURL(uc $division, {'SPECIES'=>$species});
    }
  return $hub->redirect($url);
  }
  ## ParaSite

  return sprintf '<div class="error"><h3>%s</h3><div class="error-pad"><p>%s</p>%s</div></div>',
    $error_text->[0],
    $error_text->[1],
    EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, '/ssi/species/ERROR_4xx.html')
  ;
}

1;
