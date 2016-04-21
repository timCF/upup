page = require('webpage').create()
system = require('system')
submitted = false
exit = (code) ->
	phantom.onError = () -> null
	setTimeout((() -> phantom.exit(code)), 5000)
	if page then page.close()
setTimeout((() -> exit(1)), 100000)
page.onInitialized = () ->
	page.onCallback = (data) ->
		if submitted
			arr = page.evaluate(() ->
					[].slice.call(document.getElementsByClassName('spy14'))
						.map((el) -> el.textContent.match(/^(\d+\.\d+\.\d+\.\d+).+(\:\d+)$/))
						.filter((el) -> el)
						.map((el) -> el[1]+el[2]))
			console.log(JSON.stringify(arr))
			exit(0)
		else
			page.evaluate(() ->
				document.getElementById('xpp').selectedIndex = 3
				document.getElementById('xf2').selectedIndex = 1
				document.forms[0].submit())
			submitted = true
	page.evaluate(() -> document.addEventListener('DOMContentLoaded', (() -> window.callPhantom()), false))
page.open((if system.args[1] then ('http://spys.ru/proxys/'+system.args[1]) else 'http://spys.ru/proxies/'), (() -> null))
