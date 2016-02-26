var page = require('webpage').create();
var system = require('system');
var submitted = false;
var exit = function(code){
	phantom.onError = function(){};
	setTimeout(function(){phantom.exit(code);}, 3000);
	if(page){page.close();};
};
page.onInitialized = function() {
	page.onCallback = function(data) {
		if(submitted){
			var arr = page.evaluate(function(){return [].slice.call(document.getElementsByClassName('spy14'))
				.map(function(el){return el.textContent.match(/^(\d+\.\d+\.\d+\.\d+).+(\:\d+)$/);})
				.filter(function(el){return el;})
				.map(function(el){return (el[1]+el[2]);})
					;});
			console.log(JSON.stringify(arr));
			exit(0);
		}else{
			page.evaluate(function(){
				document.getElementById('xpp').selectedIndex = 3;
				document.getElementById('xf2').selectedIndex = 1;
				document.forms[0].submit();
			});
			submitted = true;
		};
	};
	page.evaluate(function(){document.addEventListener('DOMContentLoaded', function(){window.callPhantom();}, false);});
};
page.open('http://spys.ru/proxys/'+system.args[1]+'/', function(_){});
