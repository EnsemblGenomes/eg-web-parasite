$(document).ready(function() {
  $('.result-table-sortable').dynatable({
  	table: {
    		defaultColumnIdStyle: 'trimDash'
  	},
  	features: {
    		paginate: false,
    		search: false,
    		recordCount: false,
    		perPageSelect: false,
    		pushState: false
  	},
    	readers:{
     		'Log2-fold-change' : function(el, record){
          		record.computedFoldChange = Number(el.innerHTML) || -9999999;
          		return el.innerHTML;
      		},
      		'Adjusted-p-value' : function(el, record){
        		record.computedPValue = Number(el.innerHTML) || -9999999;
        		return el.innerHTML;
      		}
    	}
  })
})
