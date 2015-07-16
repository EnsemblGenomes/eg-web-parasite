Ensembl.Panel.SpeciesExpander = Ensembl.Panel.extend({  
  init: function () {
    this.base();

    $('.expanding-header', this.el).on('click', function () {
      var id = this.id;
      var group = id.split("-")[1];
      $('#expand-' + group).toggle('slow');
      $('#key-plus-' + group).toggle();
      $('#key-minus-' + group).toggle();
    });
    
  }
});
