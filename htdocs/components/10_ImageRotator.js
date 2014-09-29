Ensembl.Panel.ImageRotator = Ensembl.Panel.extend({  
  init: function () {
    this.base();
    
    var imageArr = [];
    $('#homepage-rotator img').each(function(){
		imageArr.push($(this).attr('id'));
    });
	
	var counter = 0;
	var lastImg = 0;
	var rotateInterval;
	
	var startRotate = function() {
		rotateInterval = setInterval(function () {
			counter = counter + 1;
			if(counter >= imageArr.length) {
				counter = 0;
			}
			$('#' + imageArr[lastImg]).fadeOut("slow");
			$('#' + imageArr[counter]).fadeIn("slow");
			lastImg = counter;
		}, 10000);
	};
	
	$(document).ready(function() {
		startRotate();
	});
	
	$('#homepage-rotator').hover(function(){
		clearInterval(rotateInterval);
	}, function() {
		startRotate();
	});
    
  }
});