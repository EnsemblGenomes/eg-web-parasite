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

Ensembl.Panel.BlastSpeciesList.prototype.updateTaxonSelection = function(items) {
  var panel = this;
  var key;

  if(items.length > 0 && items[0].key != 'Multi') {
    // empty and re-populate the species list
    panel.elLk.list.empty();
    panel.elLk.checkboxes.empty();
    $.each(items, function(index, item){
      key = item.key.charAt(0).toUpperCase() + item.key.substr(1); // ucfirst
      $(panel.elLk.list).append(item.title + '<br />');
      $(panel.elLk.checkboxes).append('<input type="checkbox" name="species" value="' + key + '" checked>' + item.title + '<br />');
    });

    // update the modal link href in the form
    var modalBaseUrl = panel.elLk.modalLink.attr('href').split('?')[0];
    var keys = $.map(items, function(item){ return item.key; });
    var queryString = $.param({s: keys}, true);
    panel.elLk.modalLink.attr('href', modalBaseUrl + '?' + queryString);

    // ParaSite: select the correct checkbox
    $("input:radio[name='species_group']:checked").prop('checked', 'false');
    $("input:radio[name='species_group'][value='custom']").prop('checked', 'true');
    $('.subgroups').hide();
    $('.taxon_selector_form').show();
    //
  }
};

Ensembl.Panel.BlastForm.prototype.definedSpecies = function (taxon) {
  // User clicks a pre-defoned taxonomy group
  $('.taxon_selector_form').hide();
  $('.checkboxes').empty();
  $('.list').empty();

  var items;
  $('.subgroups').hide();
  if(taxon == 'all') {
    items = $("input[type=hidden][name='species_taxon']");
  } else {
    $('#subgroups-' + taxon).show();
    var subgroup = $("input:radio[name='species_" + taxon + "']:checked").val();
    if(subgroup == 'all') {
      items = $("input." + taxon + "[type=hidden][name='species_taxon']");
    } else {
      items = $("input." + subgroup + "[type=hidden][name='species_taxon']");
    }
  }

  $('.checkboxes').empty();
  $.each(items, function() {
    $('.checkboxes').append('<input type="checkbox" name="species" value="' + $(this).val() + '" checked>' + $(this).val() + '<br />');
  });

};

Ensembl.Panel.BlastForm.prototype.customSpecies = function () {
  // User wants to specify their own custom species list using the EG species tree selector
  $('.checkboxes').empty();
  $('.list').empty();
  $('.subgroups').hide();
  $('#species_selector').attr('href', $('#species_selector').attr('href').split('?')[0]);
  $('.taxon_selector_form').show();
  $('#species_selector').click();
};

Ensembl.Panel.BlastForm.prototype.showBlastMessage = function() {
    return false;
};


