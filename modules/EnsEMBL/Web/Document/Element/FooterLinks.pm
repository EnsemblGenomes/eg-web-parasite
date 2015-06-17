=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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
    <div class="twocol-right right">
      <a href="http://ensemblgenomes.org/info/about/wormbase_parasite">About&nbsp;WormBase ParaSite</a> | 
      <a href="/contact.html">Contact&nbsp;Us</a> | 
      <a href="http://www.ebi.ac.uk/Information/termsofuse.html">EMBL-EBI Terms of use</a> | 
      <a href="http://www.ebi.ac.uk/Information/Privacy.html">Privacy</a> | 
      <a href="http://ensemblgenomes.org/info/about/cookies">Cookies</a> 
    </div>

    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    
      ga('create', 'UA-24717231-5', 'auto');
      ga('send', 'pageview');
    
    </script>

          ) 
  ;
}

1;

