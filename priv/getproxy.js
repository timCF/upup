var page = require('webpage').create();
var system = require('system');
var exit = function(code){
	if (page) page.close();
	setTimeout(function(){ phantom.exit(code); }, 0);
	phantom.onError = function(){};
	throw new Error('');
};
page.open('http://hideme.ru/proxy-list/?maxtime=1500&ports='+system.args[1]+'&type=h&anon=34', function(status) {
	var arr = page.evaluate(function(){return [].slice.call(document.getElementsByClassName('tdl')).map(function(el){return el.textContent});});
	console.log(JSON.stringify(arr));
	exit(0);
});
