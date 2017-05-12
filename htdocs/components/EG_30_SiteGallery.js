Ensembl.Panel.SiteGalleryHome.prototype.updateIdentifier = function() {
  var species = this.elLk.species.val();

  this.elLk.identifier.val((this.params['sample_data'][species] || {})['gene'] || '');
  this.elLk.form.attr('action', this.formAction.replace('Multi',  species));
};

Ensembl.Panel.SiteGalleryHome.prototype.initSelectToToggle = function() {
  var panel = this;

  this.elLk.species.find('option').addClass(function () {
    return panel.params['sample_data'][this.value]['gene'] ? '_stt__var' : '_stt__novar';
  });

  this.elLk.dataType.parent().addClass(function () {
    return $(this).find('[value=gene]').length ? '_stt_var' : '_stt_var _stt_novar';
  });

  this.elLk.species.selectToToggle();
 
};

