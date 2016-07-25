Ensembl.updateURL = function (params, inputURL) {

//ParaSite: update the JBrowse link, if present
  if($('#jbrowse-link').length && !inputURL) {
    var url = $('#jbrowse-link').attr('href');
    // Start by splitting the JBrowse URL into it's component parts
    var tempURL = url.split("?");
    var baseURL = tempURL[0];
    var paramURL = tempURL[1].split("&");
    var jbrowseParams = {};
    for (var i in paramURL) {
      var parts = paramURL[i].split("=");
      jbrowseParams[parts[0]] = parts[1];
    }
    // Now replace the relevant parameters
    for (var i in params) {
      if(i == 'r') {
        jbrowseParams['loc'] = params[i].replace('-', '..');
      } else if(i == 'mr') {
        if(typeof params[i] !== 'undefined' && params[i] !== false) {
          jbrowseParams['highlight'] = params[i].replace('-', '..');
        } else {
          jbrowseParams['highlight'] = '';
        }
      }
    }
    //Finally, reconstruct the URL and replace in the DOM
    var newParams = [];
    for (var i in jbrowseParams) {
      newParams.push(i + '=' + jbrowseParams[i]);
    }
    var newURL = baseURL + '?' + newParams.join('&');
    $('#jbrowse-link').attr('href', newURL);
  }
//ParaSite

  var url = inputURL || window.location[this.locationURL];
  if (!url.match(/\?/)) {
    url += '?';
  }

  for (var i in params) {
    if (params[i] === false) {
      url = url.replace(new RegExp(this.hashParamRegex.replace('__PARAM__', i)), '$1');
    } else if (url.match(i + '=')) {
      var regex = new RegExp(this.hashParamRegex.replace('__PARAM__', i));

      if (url.match(regex)) {
        url = url.replace(regex, '$1$2' + params[i] + '$3');
      } else {
        url = url.replace(i + '=', i + '=' + params[i]);
      }
    } else {
      url += (url ? ';' : '') + i + '=' + params[i];
    }
  }

  url = url.replace(/([?;]);+/g, '$1').replace(/[?;&]$/, '');

  if (inputURL) {
    return url;
  }

  if (this.locationURL === 'hash') {
    url = url.replace(/^\?/, '');
    if (window.location.hash !== url) {
      window.location.hash = url;
      return true;
    }
  } else if (window.location.search !== url) {
    window.history.pushState({}, '', url);
    return true;
  }
};

