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
Ensembl.Panel.BlastSpeciesList = Ensembl.Panel.extend({

  init: function () {
    this.base();
    this.elLk.checkboxes  = $('.checkboxes', this.el);
    this.elLk.speciesList = $('.checkboxes input[name="species"]', this.el);
    this.elLk.list        = $('.list', this.el);
    this.elLk.modalLink   = $('.modal_link', this.el);
    Ensembl.species && Ensembl.species !== 'Multi' && this.updateTaxonSelection([{key: Ensembl.species, title: Ensembl.species}]);
    Ensembl.EventManager.register('updateTaxonSelection', this, this.updateTaxonSelection);
  },

  updateTaxonSelection: function(items) {
    var panel = this;
    var key;
    var new_list = [];

    // empty and re-populate the species list
    panel.elLk.list.empty();
    panel.elLk.checkboxes.empty();
    $.each(items, function(index, item){
    key = item.key.charAt(0).toUpperCase() + item.key.substr(1); // ucfirst
      var _delete = $('<span/>', {
        text: 'x',
        'class': 'ss-selection-delete',
        click: function() {
          // Update taxon selection
          var clicked_item_title = $(this).parent('li').find('span.ss-selected').html();
          var updated_items = [];

          //removing human and hence hide grch37 message
          if(clicked_item_title === "Homo_sapiens" || clicked_item_title === "Human") { panel.el.find('div.assembly_msg').hide(); }

          $.each(items, function(i, item) {
            if(clicked_item_title !== item.title) {
              updated_items.push(item);
            }
          });
          Ensembl.EventManager.trigger('updateTaxonSelection', updated_items);
          // Remove item from the Blast form list
          $(this).parent('li').remove();
        }
      });

      //adding human and hence show grch37 message
      if(item.title === "Homo_sapiens" || item.title === "Human") { panel.el.find('div.assembly_msg').show(); }

      item.img_url = Ensembl.speciesImagePath + item.key + '.png';

      var _selected_img = $('<img/>', {
        src: item.img_url,
        'class': 'nosprite'
      });

      var _selected_item = $('<span/>', {
        text: item.title,
        'data-title': item.title,
        'data-key': item.key,
        'class': 'ss-selected',
        title: item.title
      });

      var li = $('<li/>', {
      }).append(_selected_img, _selected_item, _delete).appendTo(panel.elLk.list);
      $(panel.elLk.checkboxes).append('<input type="checkbox" name="species" value="' + key + '" checked>' + item.title + '<br />');
      new_list.push(key);
    }); 

    // Check blat availability and restart
    Ensembl.EventManager.trigger('resetSearchTools', null, new_list);
    // Update sourceType on species selection change
    Ensembl.EventManager.trigger('resetSourceTypes', new_list);

    // update the modal link href in the form
    if (panel.elLk.modalLink.length) {
      var modalBaseUrl = panel.elLk.modalLink.attr('href').split('?')[0];
      var keys = $.map(items, function(item){ return item.key; });
      var queryString = $.param({s: keys, multiselect: 1, referer_action: 'Blast'}, true);
      panel.elLk.modalLink.attr('href', modalBaseUrl + '?' + queryString);
    }
  }
});

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


