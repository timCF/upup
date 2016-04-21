page = require('webpage').create()
system = require('system')
exit = (code) ->
	phantom.onError = () -> null
	setTimeout((() -> phantom.exit(code)), 5000)
	if page then page.close()
setTimeout((() -> exit(1)), 100000)
page.open('http://hideme.ru/proxy-list/?maxtime=1500&ports='+system.args[1]+'&type=h&anon=34', (_) ->
	arr = page.evaluate(() -> [].slice.call(document.getElementsByClassName('tdl')).map((el) -> el.textContent))
	console.log(arr[Math.floor(Math.random() * arr.length)])
	exit(0))
