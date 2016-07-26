Ensembl.Panel.Piechart.prototype.init = function () {
  var panel = this;

  this.base();

  if (typeof Raphael === 'undefined') {
    $.getScript('/raphael/raphael-min.js', function () {
      $.getScript('/raphael/g.raphael-min.js', function () {
        $.getScript('/raphael/g.pie-modified.js', function () { panel.getContent(); });
      });
    });
  }
};


Ensembl.Panel.Piechart.prototype.getContent = function() {
  var panel   = this;
  var visible = [];

  this.graphData   = [];
  this.graphConfig = {};
  this.graphEls    = {};
  this.dimensions  = eval($('input.graph_dimensions', this.el).val());

  // ParaSite: sometimes the order of items in the DOM doesn't match the assigned item number
  if($('input.graph_data_ordered').length > 0) {
    $('input.graph_data_ordered', this.el).each(function () {
      var id = $(this).attr('id').replace('graph_data_item_', '');
      panel.graphData[id] = eval(this.value);
    });
  } else {
    $('input.graph_data', this.el).each(function () {
      panel.graphData.push(eval(this.value));
    });
  }
  //

  $('input.graph_config', this.el).each(function () {
    panel.graphConfig[this.name] = eval(this.value);
  });

  for (i in this.graphData) {
    this.graphEls[i] = $('#graphHolder' + i);

    if (this.graphEls[i].is(':visible')) {
      visible.push(i);
    }
  }

  this.makeGraphs(visible);
};
