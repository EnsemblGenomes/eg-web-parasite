=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Component::Account;

### Base class for all the components in user accounts
### @author hr5

sub add_user_details_fields {
  ## Adds fields to a given form for registration page
  ## @param Field object to add fields to
  ## @param Hashref with keys:
  ##  - email         Email address string
  ##  - name          Name string
  ##  - organisation  Organisation string
  ##  - country       Country code
  ##  - email_notes   Notes to be added to email field
  ##  - button        Value attrib for the submit button, defaults to 'Register'
  ##  - no_consent    Flag if on, will not add the consent checkbox
  ##  - no_list       Flag if on, will not add the field "Ensembl news list subscription"
  ##  - no_email      Flag if on, will skip adding email input (for OpenID, which is unimplemented)
  my ($self, $form, $params) = @_;

  $params     ||= {};
  my @lists     = $params->{'no_list'} ? () : @{$self->hub->species_defs->SUBSCRIPTION_EMAIL_LISTS};
  my $countries = $self->object->list_of_countries;

  $form->add_field({'label' => 'Name',          'name' => 'name',         'type' => 'string',   'value' => $params->{'name'}          || '',  'required' => 1 });
  $form->add_field({'label' => 'Email Address', 'name' => 'email',        'type' => 'email',    'value' => $params->{'email'}         || '',  'required' => 1, $params->{'email_notes'} ? ('notes' => $params->{'email_notes'}) : () }) unless $params->{'no_email'};
  $form->add_field({'label' => 'Organisation',  'name' => 'organisation', 'type' => 'string' ,  'value' => $params->{'organisation'}  || '' });
  $form->add_field({'label' => 'Country',       'name' => 'country',      'type' => 'dropdown', 'value' => $params->{'country'}       || '', 'values' => [ {'value' => '', 'caption' => ''}, sort {$a->{'caption'} cmp $b->{'caption'}} map {'value' => $_, 'caption' => $countries->{$_}}, keys %$countries ] });

  if (@lists) {
    my $values = [];
    push @$values, {'value' => shift @lists, 'caption' => shift @lists, 'checked' => 0} while @lists;
    $form->add_field({
      'label'   => sprintf('%s news list subscription', $self->site_name),
      'type'    => 'checklist',
      'name'    => 'subscription',
      'notes'   => '<b>Tick to subscribe</b>. <a href="/info/about/contact/mailing.html">More information about these lists</a>.',
      'values'  => $values,
    });
  }

  my $button = {'value' => $params->{'button'} || 'Register'};
  if ($self->hub->species_defs->GDPR_VERSION && !$params->{'no_consent'}) {
    my $url = $self->hub->species_defs->GDPR_ACCOUNT_URL;
    $form->add_field({
      'label'     => 'Privacy policy',
      'type'      => 'checkbox',
      'name'      => 'accounts_consent',
      'id'        => 'consent_checkbox',
      'notes'     => qq(<b>In order to create an account please tick to agree</b> to our <a href="$url" rel="external">privacy policy</a>),
      'value'     => 1,
    });
    $button->{'type'}  = 'button';
    $button->{'id'}    = 'pre_consent';
    $button->{'class'} = 'disabled';
  }
  else {
    $button->{'type'}  = 'submit';
  }
  $form->add_button($button);
}

1;
