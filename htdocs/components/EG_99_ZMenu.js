Ensembl.Panel.ZMenu.prototype.populateNoAjax = function() {
    if (this.href && this.href.match(/http/)) {
      var domain = this.href.split('/')[2].split('.');
      var title;

      if (domain[0].match(/www\.ensembl\.org/)) {
        // URL starts with www it is ensembl, gramene or ensemblgenomes
        title = domain[1].substr(0, 1).toUpperCase() + domain[1].substr(1, domain[1].length);
      } else if (this.href.match(/\.ensembl\./)) {
        var site = domain.length > 3 ? domain[1] : domain[0];
        title = 'Ensembl' + site.substr(0, 1).toUpperCase() + site.substr(1, site.length);
      } else if (this.href.match(/\.wormbase\./)) {
        title = 'WormBase';
      }

      this.populate(false, '<tr><td colspan="2"><a href="' + this.href.replace(/ZMenu\//, '') + '">Go to ' + title + '</a></td></tr>');
    } else {
      this.base.apply(this, arguments);
    }
};

