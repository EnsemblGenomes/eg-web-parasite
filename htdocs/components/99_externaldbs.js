Ensembl.LayoutManager = Ensembl.LayoutManager.extend({
  
  externalDbUrls: function () {
    var superUrls = this.base();
    var myUrls = {
   "Caenorhabditis_elegans" : {
      "WormBase browser" : "http://www.wormbase.org/db/gb2/gbrowse/c_elegans/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_mojavensis" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dmoj/?name==###CHR###%3A###START###..###END###"
   },
   "Drosophila_willistoni" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dwil/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_melanogaster" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dmel/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_persimilis" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dper/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_grimshawi" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dgri/?name=###CHR###%3A###START###..###END###"
   },
   "Caenorhabditis_japonica" : {
      "WormBase browser" : "http://www.wormbase.org/db/gb2/gbrowse/c_japonica/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_pseudoobscura" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dpse/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_yakuba" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dyak/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_virilis" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dvir/?name=###CHR###%3A###START###..###END###"
   },
   "Caenorhabditis_brenneri" : {
      "WormBase browser" : "http://www.wormbase.org/db/gb2/gbrowse/c_brenneri/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_erecta" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dere/?name=###CHR###%3A###START###..###END###"
   },
   "Caenorhabditis_remanei" : {
      "WormBase browser" : "http://www.wormbase.org/db/gb2/gbrowse/c_remanei/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_ananassae" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dpse/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_simulans" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dsim/?name=###CHR###%3A###START###..###END###"
   },
   "Caenorhabditis_briggsae" : {
      "WormBase browser" : "http://www.wormbase.org/db/gb2/gbrowse/c_briggsae/?name=###CHR###%3A###START###..###END###"
   },
   "Drosophila_sechellia" : {
      "FlyBase browser" : "http://flybase.org/cgi-bin/gbrowse/dsec/?name=###CHR###%3A###START###..###END###"
   },
   "Pristionchus_pacificus" : {
      "WormBase browser" : "http://www.wormbase.org/db/gb2/gbrowse/p_pacificus/?name=###CHR###%3A###START###..###END###"
   }
}
;
    var merged = $.extend(superUrls, myUrls);
    return merged;
  }
});
