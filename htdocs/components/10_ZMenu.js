Ensembl.Panel.ZMenu.prototype.populateAjax = function(url, expand) {
	var timeout = this.timeout;
	url     = url || this.href;
    if(url && url.match('www.wormbase.org')) {
      this.populateNoAjax();
    } else if (url && url.match('/ZMenu/')) {
      $.extend($.ajax({
        url:      url,
        data:     this.coords.clickStart ? { click_chr: this.coords.clickChr || Ensembl.location.name, click_start: this.coords.clickStart, click_end: this.coords.clickEnd } : {},
        dataType: this.crossOrigin ? 'jsonp' : 'json',
        context:  this,
        success:  $.proxy(this.buildMenuAjax,  this),
        error:    $.proxy(this.populateNoAjax, this)
      }), { timeout: timeout, expand: expand });
    } else {
      this.populateNoAjax();
    }
};

