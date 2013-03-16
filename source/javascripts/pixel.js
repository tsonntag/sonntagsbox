$(document).ready(function(){
	function rand(n){return Math.random()*n;};
	function nrand(n){return Math.floor(rand(n));};
	RGBColour.rand = function(){return new RGBColour(nrand(256),nrand(256),nrand(256));};
	HSVColour.rand = function(){return new HSVColour(rand(360),rand(100),rand(100));};
	HSLColour.rand = function(){return new HSLColour(rand(360),rand(100),rand(100));};
	function colourType() {return $('input:radio[name=colourType]:checked').val()};
	function render(){
		var canvas = document.getElementById('canvas');
		var c = canvas.getContext('2d');
		var dy = 40, dx = 40, ny = 20, nx = 20; 
		for(y=0; y < dy*ny; y+=dy ){ 
			for(x=0; x < dx*nx; x+=dx){ 
		    c.beginPath();
				c.rect(x,y,dx,dy);
				c.fillStyle = eval(colourType()).rand().getCSSHexadecimalRGB();
				c.fill();
			}
		}
	}
	$('input:radio[name=colourType]').click(function(){render();});
	$('#refresh').click(function(){render();});

	render();

	//canvas.src = canvas.toDataUrl();
});
