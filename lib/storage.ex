defmodule Upup.Storage do
	use Silverb, [
		{"@pool", :upup}
	]

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

	def get_tasks(uid) do
		"SELECT id, uid, task_name, ttl FROM tasks WHERE uid = ?;"
		|> Sqlx.exec([uid], @pool)
		|> Enum.map(fn(%{id: id, uid: uid, task_name: task_name, ttl: ttl}) -> %Upup.Task{id: id, uid: uid, task_name: task_name, ttl: ttl} end)
	end

	def get_albums4task(%Upup.Task{id: id, ttl: ttl}) do
		"SELECT gid, aid, task_id, album_name, upload_result FROM albums WHERE task_id = ? AND TIMESTAMPDIFF(SECOND, stamp, NOW()) > ?;"
		|> Sqlx.exec([id, ttl], @pool)
		|> Enum.map(fn(%{gid: gid, aid: aid, task_id: task_id, album_name: album_name, upload_result: upload_result}) -> %Upup.Album{gid: gid, aid: aid, task_id: task_id, album_name: album_name, upload_result: upload_result} end)
	end

	def update_album(%Upup.Album{gid: gid, aid: aid, task_id: tid}, bin) do
		%{error: []} = "UPDATE albums SET upload_result = ? WHERE gid = ? AND aid = ? AND task_id = ?;" |> Sqlx.exec([bin, gid, aid, tid], @pool)
	end

	def get_items4task(%Upup.Task{id: id}) do
		"SELECT link, task_id, caption FROM items WHERE task_id = ?;"
		|> Sqlx.exec([id], @pool)
		|> Enum.map(fn(%{link: link, task_id: task_id, caption: caption}) -> %Upup.Item{link: link, task_id: task_id, caption: caption} end)
	end

end
