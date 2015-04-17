Ensembl.Panel.ZMenu.prototype.populateNoAjax = function() {
  
    if (this.href && this.href.match(/http/)) {
      var domain = this.href.split('/')[2].split('.');
      var title;
      var url = this.href.replace(/ZMenu\//, '');

      if (this.href.match(/www\.ensembl\.org/)) {
        title = 'Ensembl';
      } else if (this.href.match(/\.ensembl\./)) {
        var site = domain.length > 3 ? domain[1] : domain[0];
        title = 'Ensembl ' + site.substr(0, 1).toUpperCase() + site.substr(1, site.length);
      } else if (this.href.match(/\.wormbase\./)) {
        title = 'WormBase';
      }

      this.populate(false, '<tr><td colspan="2"><a href="' + url + '">Go to ' + title + '</a></td></tr>');
    } else {
      this.base.apply(this, arguments);
    }
    
};

