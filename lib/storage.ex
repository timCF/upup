defmodule Upup.Storage do
	use Silverb, [
		{"@pool", :upup}
	]


	def save_account(data = %{uid: _, country: _, token: _}) do
		%{error: []} = Sqlx.insert_duplicate([data], [:uid, :country, :token], [:uid], "accounts", @pool)
		:ok
	end


	def get_active_accounts do
		"""
		SELECT
			tasks.uid AS uid,
			accounts.token AS token,
			accounts.country AS country
		FROM tasks
		LEFT JOIN accounts
		ON tasks.uid = accounts.uid;
		"""
		|> Sqlx.exec([], @pool)
		|> Stream.map(fn(%{uid: uid, token: token, country: country}) -> %Upup.Account{uid: uid, token: token, country: country} end)
		|> Enum.uniq
	end
	def get_account_details(uid) do
		[%{uid: uid, token: token, country: country}] = "SELECT uid, token, country FROM accounts WHERE uid = ?;" |> Sqlx.exec([uid], @pool)
		%Upup.Account{uid: uid, token: token, country: country}
	end


	def new_tasks(tasks = [_|_]) do
		%{error: []} = Sqlx.insert_ignore(tasks, [:uid, :task_name, :ttl], "tasks", @pool)
		:ok
	end
	def save_task(subj = %{uid: uid, id: id}) do
		[%{uid: ^uid}] = "SELECT uid FROM tasks WHERE id = ?;" |> Sqlx.exec([id], @pool)
		keys = Map.keys(subj) |> Enum.filter(&(not(&1 in [:uid, :id])))
		case	Stream.map(keys, &("UPDATE tasks SET #{&1} = ? WHERE id = #{id}"))
				|> Enum.join(";")
				|> Sqlx.exec(Enum.map(keys, &(Map.get(subj,&1))), @pool) do
			%{error: []} -> :ok
			%{error: error} -> {:error, error}
		end
	end
	def delete_task(%{uid: uid, id: id}) do
		[%{uid: ^uid}] = "SELECT uid FROM tasks WHERE id = ?;" |> Sqlx.exec([id], @pool)
		%{error: []} = "DELETE FROM tasks WHERE id = ?;" |> Sqlx.exec([id], @pool)
		:ok
	end


	def get_tasks(uid) do
		"SELECT id, uid, task_name, ttl FROM tasks WHERE uid = ?;"
		|> Sqlx.exec([uid], @pool)
		|> Enum.map(fn(%{id: id, uid: uid, task_name: task_name, ttl: ttl}) -> %Upup.Task{id: id, uid: uid, task_name: task_name, ttl: ttl} end)
	end
	def get_albums_map([]), do: %{}
	def get_albums_map(tasks = [_|_]) do
		"SELECT id, gid, aid, task_id, album_name, upload_result FROM albums WHERE task_id IN (?);"
		|> Sqlx.exec([Stream.map(tasks,fn(%Upup.Task{id: id}) -> id end) |> Enum.uniq], @pool)
		|> Enum.group_by(fn(%{task_id: tid}) -> tid end)
	end
	def get_items_map([]), do: %{}
	def get_items_map(tasks = [_|_]) do
		"SELECT id, link, task_id, caption FROM items WHERE task_id IN (?);"
		|> Sqlx.exec([Stream.map(tasks,fn(%Upup.Task{id: id}) -> id end) |> Enum.uniq], @pool)
		|> Enum.group_by(fn(%{task_id: tid}) -> tid end)
	end


	def get_albums4task(%Upup.Task{id: id, ttl: ttl}) do
		"SELECT gid, aid, task_id, album_name, upload_result FROM albums WHERE task_id = ? AND ((TIMESTAMPDIFF(SECOND, stamp, NOW()) > ?) OR (upload_result != 'ok'));"
		|> Sqlx.exec([id, ttl], @pool)
		|> Enum.map(fn(%{gid: gid, aid: aid, task_id: task_id, album_name: album_name, upload_result: upload_result}) -> %Upup.Album{gid: gid, aid: aid, task_id: task_id, album_name: album_name, upload_result: upload_result} end)
	end
	def get_items4task(%Upup.Task{id: id}) do
		"SELECT link, task_id, caption FROM items WHERE task_id = ?;"
		|> Sqlx.exec([id], @pool)
		|> Enum.map(fn(%{link: link, task_id: task_id, caption: caption}) -> %Upup.Item{link: link, task_id: task_id, caption: caption} end)
	end


	def update_album(%Upup.Album{gid: gid, aid: aid, task_id: tid}, bin) do
		%{error: []} = "UPDATE albums SET upload_result = ? WHERE gid = ? AND aid = ? AND task_id = ?;" |> Sqlx.exec([bin, gid, aid, tid], @pool)
	end


	def new_album(data = %{task_id: id}, uid) do
		[%{uid: ^uid}] = "SELECT uid FROM tasks WHERE id = ?;" |> Sqlx.exec([id], @pool)
		%{error: []} = [Map.put(data, :upload_result, "ok")] |> Sqlx.insert_ignore([:gid, :aid, :task_id, :album_name, :upload_result], "albums", @pool)
		:ok
	end
	def save_album(data = %{}, uid, id) do
		[%{uid: ^uid}] = "SELECT tasks.uid AS uid FROM tasks LEFT JOIN albums ON albums.task_id = tasks.id WHERE albums.id = ?;" |> Sqlx.exec([id], @pool)
		keys = Map.keys(data)
		case	Stream.map(keys, &("UPDATE albums SET #{&1} = ? WHERE id = #{id}"))
				|> Enum.join(";")
				|> Sqlx.exec(Enum.map(keys, &(Map.get(data,&1))), @pool) do
			%{error: []} -> :ok
			%{error: error} -> {:error, error}
		end
	end
	def delete_album(%{uid: uid, id: id}) do
		[%{uid: ^uid}] = "SELECT tasks.uid AS uid FROM tasks LEFT JOIN albums ON albums.task_id = tasks.id WHERE albums.id = ?;" |> Sqlx.exec([id], @pool)
		%{error: []} = "DELETE FROM albums WHERE id = ?;" |> Sqlx.exec([id], @pool)
		:ok
	end


	def new_item(data = %{task_id: id}, uid) do
		[%{uid: ^uid}] = "SELECT uid FROM tasks WHERE id = ?;" |> Sqlx.exec([id], @pool)
		%{error: []} = Sqlx.insert_ignore([data], [:link, :task_id, :caption], "items", @pool)
		:ok
	end
	def save_item(data = %{}, uid, id) do
		[%{uid: ^uid}] = "SELECT tasks.uid AS uid FROM tasks LEFT JOIN items ON items.task_id = tasks.id WHERE items.id = ?;" |> Sqlx.exec([id], @pool)
		keys = Map.keys(data)
		case	Stream.map(keys, &("UPDATE items SET #{&1} = ? WHERE id = #{id}"))
				|> Enum.join(";")
				|> Sqlx.exec(Enum.map(keys, &(Map.get(data,&1))), @pool) do
			%{error: []} -> :ok
			%{error: error} -> {:error, error}
		end
	end
	def delete_item(%{uid: uid, id: id}) do
		[%{uid: ^uid}] = "SELECT tasks.uid AS uid FROM tasks LEFT JOIN items ON items.task_id = tasks.id WHERE items.id = ?;" |> Sqlx.exec([id], @pool)
		%{error: []} = "DELETE FROM items WHERE id = ?;" |> Sqlx.exec([id], @pool)
		:ok
	end


end
