var page = require('webpage').create();
var system = require('system');
var exit = function(code){
	setTimeout(function(){ phantom.exit(code); }, 1000);
	if(page){page.close()};
	phantom.onError = function(){};
};
page.open('http://hideme.ru/proxy-list/?maxtime=1500&ports='+system.args[1]+'&type=h&anon=34', function(status) {
	var arr = page.evaluate(function(){return [].slice.call(document.getElementsByClassName('tdl')).map(function(el){return el.textContent});});
	console.log(JSON.stringify(arr));
	exit(0);
});
