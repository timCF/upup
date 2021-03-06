#
#	constants, defaults as callbacks arity 0
#
constants =
	default_opts: () -> {
		blocks: [{val: "main_page", lab: "задачи"},{val: "about", lab: "о программе"}]
		sidebar: false
		showing_block: "main_page"
		version: '__VERSION__'
		token: false
		country: "RU"
	}
	colors: () -> {red: '#CC3300', yellow: '#FFFF00', pink: '#FF6699'}
#
#	state for jade
#
init_state =
	data: {
		is_logined: false,
		is_locked: false,
		is_entering: false,
		userdata: false,
		editable: {
			tasks: {},
			albums: {},
			items: {}
		}
		new: {
			task: {},
			album: {},
			item: {}
		}
		cache: {}
	}
	handlers: {
		#
		#	app local handlers
		#
		edit_create: (field, path, ev) ->
			if (ev? and ev.target? and ev.target.value?)
				tmp = ev.target.value
				actor.cast((state) ->
					if not(Imuta.get_in(state, path)) then (state = Imuta.put_in(state, path, {}))
					Imuta.put_in(state, path.concat([field]), tmp))
		new_task: () ->
			actor.cast((state) ->
				to_server("new_task", {token: state.opts.token, country: state.opts.country, data: state.data.new.task})
				state)
		save_task: (id) ->
			actor.cast((state) ->
				to_server("save_task", {token: state.opts.token, country: state.opts.country, data: state.data.editable.tasks[id], id: id})
				state)
		delete_task: (id) ->
			actor.cast((state) ->
				to_server("delete_task", {token: state.opts.token, country: state.opts.country, id: id})
				state)
		new_album: (album, task_id) ->
			actor.cast((state) ->
				to_server("new_album", {token: state.opts.token, country: state.opts.country, task_id: task_id, album: album})
				state)
		save_album: (data, id) ->
			actor.cast((state) ->
				to_server("save_album", {token: state.opts.token, country: state.opts.country, data: data, id: id})
				state)
		delete_album: (id) ->
			actor.cast((state) ->
				to_server("delete_album", {token: state.opts.token, country: state.opts.country, id: id})
				state)
		new_item: (item, task_id) ->
			actor.cast((state) ->
				if state.handlers.check_link(item)
					to_server("new_item", {token: state.opts.token, country: state.opts.country, task_id: task_id, data: item})
				else
					error("неверный формат ссылки, можно загружать фото только с сайта vk.com")
				state)
		save_item: (data, id) ->
			actor.cast((state) ->
				if state.handlers.check_link(data)
					to_server("save_item", {token: state.opts.token, country: state.opts.country, id: id, data: data})
				else
					error("неверный формат ссылки, можно загружать фото только с сайта vk.com")
				state)
		delete_item: (id) ->
			actor.cast((state) ->
				to_server("delete_item", {token: state.opts.token, country: state.opts.country, id: id})
				state)
		check_link: (item) ->
			link = item.link
			if Imuta.is_string(link)
				link.match(/^http(s)?\:\/\/(cs|pp)\d*\.vk\.me/)
			else
				true
		#
		#	some main-purpose handlers
		#
		change_from_view: (path, ev) ->
			if (ev? and ev.target? and ev.target.value?)
				tmp = ev.target.value
				actor.cast((state) -> Imuta.put_in(state, path, tmp))
		change_from_view_swap: (path) -> actor.cast( (state) -> Imuta.update_in(state, path, (bool) -> not(bool)) )
		show_block: (some) -> actor.cast( (state) -> (state.opts.showing_block = some) ; state )
		#
		#	local storage
		#
		get_last_version: () ->
			val = actor.get().data.cache.last_version
			if not(val)
				res = $.ajax({type: 'GET', async: false, url: "http://"+location.host+"/version.json"}).responseJSON.versionExt
				actor.cast((state) ->
					if Imuta.is_string(res) then state.data.cache.last_version = res
					state)
				res
			else
				val
		reset_opts: () -> actor.cast((state) ->
			state.opts = constants.default_opts()
			store.remove("opts")
			state)
		save_opts: () -> actor.cast((state) ->
			store.set("opts", state.opts)
			state)
		# use it only on start of application
		load_opts: () ->
			from_storage = store.get("opts")
			if from_storage then actor.cast((state) -> state.opts = from_storage ; state) else actor.get().handlers.reset_opts()
			last_version = actor.get().handlers.get_last_version()
			actor.cast((state) ->
				this_version = state.opts.version
				if not(Imuta.equal(this_version, last_version)) then error("Доступен клиент версии "+last_version+" но, вы используете клиент версии "+this_version+". Настоятельно рекомендуется сбросить опции, почистить кеш и обновить страницу.")
				state.opts.showing_block = constants.default_opts().showing_block
				state.opts.sidebar = constants.default_opts().sidebar
				state)
		log_in: () ->
			actor.cast((state) ->
				state.handlers.save_opts()
				to_server("get_account_data", {token: state.opts.token, country: state.opts.country})
				state.data.is_entering = true
				state)
	}
#
#	actor to not care abount concurrency
#
actor = new Act(init_state, "pure", 500)

#
#	messages
#
update_state = () ->
	actor.cast((state) ->
		if (state.data.is_logined or state.data.is_entering) then to_server("get_account_data", {token: state.opts.token, country: state.opts.country})
		state)
	setTimeout(update_state, 3000)
to_server = (subject, content) ->
	if ((subject != "ping") and (subject != "get_account_data"))
		actor.cast((state) ->
			state.data.is_locked = true
			state)
	bullet.send(JSON.stringify({"subject": subject,"content": content}))
#
#	view renderers
#
widget = require("widget")
domelement    = null
do_render = () -> React.render(widget(actor.get()), domelement) if domelement?
render_process = () ->
	try
		do_render()
	catch error
		console.log error
	setTimeout( (() -> actor.zcast(() -> render_process())) , 500)
#
#	notifications
#
error = (mess) ->
	$.growl.error({ message: mess , duration: 20000})
warn = (mess) ->
	$.growl.warning({ message: mess , duration: 20000})
notice = (mess) ->
	$.growl.notice({ message: mess , duration: 20000})
#
#	bullet handlers
#
bullet = $.bullet("ws://" + location.hostname + ":8041/bullet")
document.addEventListener "DOMContentLoaded", (e) ->
	domelement  = document.getElementById("main_frame")
	actor.get().handlers.load_opts()
	actor.zcast(() -> render_process())
	bullet.onopen = () ->
		notice("bullet websocket: соединение с сервером установлено")
		update_state()
	bullet.ondisconnect = () -> error("bullet websocket: соединение с сервером потеряно")
	bullet.onclose = () -> warn("bullet websocket: соединение с сервером закрыто")
	bullet.onheartbeat = () -> to_server("ping","nil")
	bullet.onmessage = (e) ->
		mess = $.parseJSON(e.data)
		subject = mess.subject
		content = mess.content
		if (subject != "pong")
			actor.cast((state) ->
				if (subject != "get_account_data") then (state.data.is_locked = false)
				state.data.is_entering = false
				state)
		switch subject
			when "pong" then "ok"
			when "error" then error(content)
			when "warn" then warn(content)
			when "notice" then notice(content)
			when "get_account_data"
				actor.cast((state) ->
					state.data.userdata = content
					state.data.is_logined = true
					state)
			else alert("subject : "+subject+" | content : "+content)
