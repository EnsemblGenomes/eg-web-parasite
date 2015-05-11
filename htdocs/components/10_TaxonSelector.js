Ensembl.Panel.TaxonSelector.prototype.updateConfigurationBLAST = function() {
    var panel = this;
    var items = panel.getSelectedItems();
    if (panel.selectionLimit && items.length > panel.selectionLimit && $("input:radio[id='individual']").is(":checked")) {
        alert('Too many items selected.\nPlease select a maximum of ' + panel.selectionLimit + ' items or choose to submit the species as a single job.');
	$("input:radio[id='concat']").prop('checked', 'true');
	Ensembl.EventManager.trigger('updateTaxonSelection', items);
        return false;
    } else {
        Ensembl.EventManager.trigger('updateTaxonSelection', items);
        return true;
    }
};

