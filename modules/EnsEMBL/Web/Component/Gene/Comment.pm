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

package EnsEMBL::Web::Component::Gene::Comment;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;
use base qw(EnsEMBL::Web::Component);
use Data::Dumper;

sub content {
  my $self        = shift;

  my $hub         = $self->hub;
  my $object      = $self->object;
  my $stable_id   = $hub->param('g');
## ParaSite: can't use the species name as it contains the BioProject 
  my $species     = $hub->species_defs->SPECIES_SCIENTIFIC_NAME;
  my $gxa_url     = $SiteDefs::GXA_EBI_URL;
  my $gxa_gene_url = $SiteDefs::GXA_REST_URL;
##
  my $html;

  $species        =~ s/_/ /gi; #GXA require the species with no underscore.  

  $html = sprintf '<h3> User Comment for Gene %s</h3>', $stable_id;

  # my $users_available = $hub->users_available;
  # my $user = $users_available ? $hub->user : undef;

  my $user = $hub->user;
  my $submit_area_css_class = 'cmt_hidden';
  if($hub->users_available && $user) {
    #$html .= sprintf '<h3> Welcome user id %s and email %s</h3>', $user, $user->email;
    $submit_area_css_class = '';
    #$html .= sprintf '<div id="current_user_email_id" data-value="%s"></div>', $hub->user->email;
  } else {
    $html .= '<h3> You need to <a class="constant modal_link" href="/Multi/Account/Login">Login</a> first to write a comment </h3>';
  }


  $html .= qq {
<div id="gene_stable_id" data-value="$stable_id"></div>
<div id="commentbox">
  <div class="wrapper">
    <div id="cmt_section1"></div>
    <div id="cmt_section2" class="$submit_area_css_class">
      <div class="input_area">
        <textarea placeholder="Write your comment here!" class="content_input"></textarea>
        <input value="Submit" name="submit" class="fbutton cbutton" id="cm9012" type="submit" data-role="none">
      </div>
    </div>
  </div>
</div>};

  return $html;
}

1;