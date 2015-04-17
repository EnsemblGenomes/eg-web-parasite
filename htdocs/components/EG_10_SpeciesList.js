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

Ensembl.Panel.SpeciesList = Ensembl.Panel.extend({  
  init: function () {
    this.base();
    
    var reorder    = $('.reorder_species');
    var full       = $('.full_species');
    var favourites = $('.favourites');
    var container  = $('.species_list_container');
    var dropdown   = $('.dropdown_redirect',this.el);
    var ac         = $('#species_autocomplete',this.el);
    
    ac.autocomplete({
      minLength: 3,
      source: '/Multi/Ajax/species_autocomplete',
      select: function(event, ui) { if (ui.item) Ensembl.redirect('/' + ui.item.production_name + '/Info/Index') },
      search: function() { ac.addClass('loading') },
      response: function(event, ui) {
        ac.removeClass('loading');
        if (ui.content.length || ac.val().length < 3) {
          ac.removeClass('invalid');
        } else {
          ac.addClass('invalid');
        }
      }
    }).focus(function(){
      // add placeholder text
      if($(this).val() == $(this).attr('title')) {
        ac.val('');
        ac.removeClass('inactive');
      } else if($(this).val() != '') {
        ac.autocomplete('search');
      }
    }).blur(function(){
      // remove placeholder text
      ac.removeClass('invalid');
      ac.addClass('inactive');
    }).keyup(function(){
      ac.removeClass('invalid');
    }).data("ui-autocomplete")._renderItem = function (ul, item) {
      // highlight the term within each match
      var regex = new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(this.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi");
      item.label = item.label.replace(regex, "<strong>$1</strong>");
      return $("<li></li>").data("ui-autocomplete-item", item).append("<a>" + item.label + "</a>").appendTo(ul);
    };
        
    if (!reorder.length || !full.length || !favourites.length) {
      return;
    }
    
    $('.toggle_link', this.el).on('click', function () {
      reorder.toggle();
      full.toggle();
    });
    
    $('select.dropdown_redirect', this.el).on('change', function () {
      Ensembl.redirect(this.value);
    });
    
  }
});
