Ensembl.Panel.Content.prototype.enableBlastButton = function(seq) {
    var panel = this;

    if (!this.blastButtonEnabled) {

      this.elLk.blastButton = this.el.find('._blast_button').removeClass('modal_link').filter(':not(._blast_no_button)').removeClass('hidden').end().on('click', function(e) {
        e.preventDefault();
        panel.runBlastSeq();
      });

      // rel attribute takes precedence over the sequence parsed on page
      seq = this.elLk.blastButton.prop('rel') || seq;

      if (seq && this.elLk.blastButton.length) {

        // ParaSite: swap round the key and values
        this.elLk.blastForm = $('<form>').appendTo(document.body).hide()
          .attr({action: this.elLk.blastButton.attr('href'), method: 'post'})
          .append($.map(Ensembl.coreParams, function(v, n) { return $('<input type="hidden" name="' + n + '" value="' + v + '" />'); }))
          .append($('<input type="hidden" name="query_sequence" value="' + this.filterBlastSeq(seq) + '" />'));
        //

        this.blastButtonEnabled = true;
      }
    }

    return this.blastButtonEnabled;
};

