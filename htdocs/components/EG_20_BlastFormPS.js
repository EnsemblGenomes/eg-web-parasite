/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.BlastForm.prototype.getSelectedSpecies = function() {
  this.elLk.speciesCheckboxes = this.elLk.form.find('input[name=species]');
  return this.elLk.speciesCheckboxes.filter(':checked').map(function() { return this.value; } ).toArray();
};

Ensembl.Panel.BlastForm.prototype.checkSpeciesChecked = function () {
  var count = $("input:checkbox[name='species']:checked").length;
  var limit = 25;
  if(count > limit) {
    alert('Too many items selected.\nPlease select a maximum of ' + limit + ' items or choose to submit the species as a single job.');
    $("input:radio[id='concat']").prop('checked', 'true');
  }
};

Ensembl.Panel.BlastForm.prototype.showBlastMessage = function() {
    var notified    = Ensembl.cookie.get('ncbiblast_notified');

    if (!notified) {
      $(['<div class="blast-message hidden">',
        '<div></div>',
        '<p><b>PLEASE NOTE</b></p>',
        '<p>As of release 3, this tool is using <a href="http://www.ebi.ac.uk/Tools/sss/ncbiblast/">NCBI BLAST+</a> instead of <a href="http://www.ebi.ac.uk/Tools/sss/wublast/">WU-BLAST</a>. Consequently new jobs may generate different results to existing saved jobs.</p>',
        '<p><button>Don\'t show this again</button></p>',
        '</div>'
      ].join(''))
        .appendTo(document.body).show().find('button,div').on('click', function (e) {
          Ensembl.cookie.set('ncbiblast_notified', 'yes');
          $(this).parents('div').first().fadeOut(200);
      }).filter('div').helptip({content:"Don't show this again"});
      return true;
    }

    return false;
};


