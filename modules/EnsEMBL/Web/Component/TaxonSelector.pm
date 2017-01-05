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

package EnsEMBL::Web::Component::TaxonSelector;

sub render_tip {
  my $self = shift;
 
## ParaSite: remove text relating to species limit [PARASITE-126]
  my $tip_text = $self->{tip_text};
##

  return qq{
    <div class="info">
      <h3>Tip</h3>
      <div class="error-pad">
        <p>
          $tip_text
        </p>
      </div>
    </div>
  };
}

1;

