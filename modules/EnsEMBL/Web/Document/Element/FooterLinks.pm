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

package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

sub content {

 return qq(
   <div class="footerlinks twocol-right right">
     <h3>
       Information
     </h3>
     <ul>
       <li><a  href="http://ensemblgenomes.org/info/about/wormbase_parasite">About&nbsp;WormBase ParaSite</a></li>
       <li><a  href="/info/datausage.html">Data Usage</a></li>
       <li><a  href="/info/">Help and Documentation</a></li>
       <li><a  href="/Help/Contact" class="popup">Contact&nbsp;Us</a></li>
       <li><a  href="http://www.ebi.ac.uk/Information/termsofuse.html">EMBL-EBI Terms of use</a></li>
       <li><a  href="http://www.ebi.ac.uk/Information/Privacy.html">Privacy</a></li>
       <li><a  href="http://www.ebi.ac.uk/about/cookie-control">Cookies</a></li> 
     </ul>
   </div>
         ) 
 ;
}

1;

