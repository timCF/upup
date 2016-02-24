var page = require('webpage').create();
var system = require('system');
page.open('http://hideme.ru/proxy-list/?country='+system.args[1]+'&maxtime=3000&ports='+system.args[2]+'&type=s&anon=34', function(status) {
	var arr = page.evaluate(function(){return [].slice.call(document.getElementsByClassName('tdl')).map(function(el){return el.textContent});});
	console.log(JSON.stringify(arr));
	phantom.exit();
});
