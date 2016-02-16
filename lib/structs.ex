defmodule Upup.Account do
	defstruct	uid: nil,
				token: nil,
				country: nil
end
defmodule Upup.Task do
	defstruct	id: nil,
				uid: nil,
				task_name: nil,
				ttl: nil
end
defmodule Upup.Item do
	defstruct	link: nil,
				task_id: nil,
				caption: ""
end
defmodule Upup.Album do
	defstruct	gid: nil,
				aid: nil,
				task_id: nil,
				album_name: "",
				upload_result: "ok"
end
