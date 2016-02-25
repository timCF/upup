var page = require('webpage').create();
var system = require('system');
page.open('http://spys.ru/proxys/'+system.args[1]+'/', function(status) {
	page.onLoadFinished = function(_){
		var arr = page.evaluate(function(){return [].slice.call(document.getElementsByClassName('spy14'))
			.map(function(el){return el.textContent.match(/^(\d+\.\d+\.\d+\.\d+).+(\:\d+)$/);})
			.filter(function(el){return el;})
			.map(function(el){return (el[1]+el[2]);})
				;});
		console.log(JSON.stringify(arr));
		phantom.exit();
	};
	page.evaluate(function(){
		document.getElementById('xpp').selectedIndex = 3;
		document.getElementById('xf2').selectedIndex = 1;
		document.forms[0].submit();
	});
});
