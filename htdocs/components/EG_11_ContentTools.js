Ensembl.Panel.ContentTools.prototype.parseJSONResponseHeader = function(json) {
	/*
	* This parses the header for status as packed inside the JSON object
	* Not to be confused with the actual HTTP header
	*/
	var header = json.header || {};
	switch (parseInt(header.status)) {
	  case 200:
		// continue with response handling
		return true;
	  case 302:
		// handle redirection
		if (header.location) {
		  this.ajax({'url' : header.location, 'async': false});
		} else {
		  this.showError('Redirect URL is missing', 'Redirection Error');
		}
		return false;
	  case 404:
		// not found
		this.showError('The requested page could not be found.', 'Not found');
		return false;
	  case 500:
		// server error
		var exception = json.exception || {};
		this.showError('There was a problem with one of the tools servers. Please report this issue to parasite-help@sanger.ac.uk, giving your job ticket id if possible.', 'Server Error: ' + exception.type);
		return false;
	  default:
		// not likely to come here, but anyway...
		this.showError();
		return false;
	}
};
