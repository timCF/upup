defmodule Upup.Worker do
	use Silverb, [{"@ttl", :timer.seconds(30)}]
	use GenServer

	def start_link(args), do: GenServer.start_link(__MODULE__, args)

	def init(uid) do
		Upup.notice("start worker #{Integer.to_string(uid)}")
		<<a::32,b::32,c::32>> = :crypto.rand_bytes(12)
		_ = :random.seed(a,b,c)
		{:ok, Upup.Storage.get_account_details(uid), 1}
	end
	def handle_info(:timeout, account = %Upup.Account{country: country, uid: uid}) do
		case Tinca.memo(&getproxy/1, [country], :timer.minutes(5)) |> Enum.shuffle do
			[] ->
				{:noreply, account, @ttl}
			[proxy|_] ->
				case Upup.Storage.get_tasks(uid) do
					[] ->
						{:stop, :normal, nil}
					tasks = [_|_] ->
						Enum.each(tasks, &(process_task(&1, account, proxy)))
						{:noreply, Upup.Storage.get_account_details(uid), @ttl}
				end
		end
	end
	def terminate(reason, state) do
		Upup.warm("terminate worker #{inspect state}, reason #{inspect reason}")
		:ok
	end

	defp getproxy(country) do
		case System.cmd("phantomjs", ["#{Exutils.priv_dir(:upup)}/getproxy.js",country]) do
			{text, 0} when is_binary(text) ->
				case Jazz.decode(text) do
					{:ok, lst = [_|_]} -> lst
					some ->
						Upup.error("error on decoding proxy-list for country #{country}, got #{inspect some}, #{text}")
						[]
				end
			some ->
				Upup.error("error on getting proxy-list for country #{country}, got #{inspect some}")
				[]
		end
	end

	defp process_task(task = %Upup.Task{}, account = %Upup.Account{}, proxy) do
		# here use stamp
		case Upup.Storage.get_albums4task(task) do
			[] -> :ok
			albums = [_|_] ->
				case  Upup.Storage.get_items4task(task) |> Enum.shuffle do
					[] -> Upup.error("can not get items for task #{inspect task}")
					[item = %Upup.Item{}|_] -> Enum.each(albums, &(update_process(&1, item, account, proxy)))
				end
		end
	end

	defp update_process(album = %Upup.Album{}, item = %Upup.Item{}, account = %Upup.Account{}, proxy) do
		case cleanup_user_photos(album, account, proxy) do
			:ok ->	case upload_item(album, item, account, proxy) do
						:ok ->
							Upup.Storage.update_album(album, "ok")
						{:error, error} ->
							message = "ERROR ON UPLOAD USER PHOTOS #{error}, acc #{inspect account}"
							Upup.error(message)
							Upup.Storage.update_album(album, message)
					end
			{:error, error} -> Upup.error("ERROR ON CLENUP USER PHOTOS #{error}, acc #{inspect account}")
		end
	end

	defp cleanup_user_photos(album = %Upup.Album{gid: gid, aid: aid}, %Upup.Account{token: token, uid: uid}, proxy) do
		fn() ->
			case Exvk.Photos.get(%{gid: gid, aid: aid}, token, proxy) do
				{:error, error} -> {:error, "error on getting photos 4 album #{inspect album} => #{inspect error}"}
				lst when is_list(lst) ->
					case Stream.filter_map(lst,
							fn(%{user_id: user_id}) -> user_id == uid end,
							fn(%{pid: pid}) -> pid end) |> Enum.uniq do
						[] -> :ok
						pids = [_|_] ->
							case Stream.map(pids, &(Exvk.Photos.delete(%{gid: gid, pid: &1}, token, proxy))) |> Enum.filter(&(&1 != :ok)) do
								[] -> :ok
								errors = [_|_] -> {:error, "error on deleting pids from album #{inspect album} => #{inspect errors}"}
							end
					end
			end
		end
		|> Exutils.retry(&(&1 == :ok), 5)
	end

	defp upload_item(%Upup.Album{gid: gid, aid: aid}, item = %Upup.Item{caption: caption}, %Upup.Account{token: token}, proxy) do
		fn() ->
			case tmp_save(item) do
				error = {:error, _} -> error
				{:ok, filename} ->
					case Exvk.Photos.upload(%{gid: gid, aid: aid, path: filename, caption: caption}, token, proxy) do
						:ok ->
							File.rm!(filename)
							:ok
						{:error, error} ->
							File.rm!(filename)
							{:error, "upload file error #{inspect error}"}
					end
			end
		end
		|> Exutils.retry(&(&1 == :ok), 5)
	end

	def tmp_save(%Upup.Item{link: link}) do
		case HTTPoison.get(link) do
			{:ok, %HTTPoison.Response{status_code: 200, body: bin}} when is_binary(bin) ->
				filename = Exutils.priv_dir(:upup)<>"/tmp/"<>Exutils.make_uuid<>"."<>(String.split(link,".") |> List.last)
				File.write!(filename, bin)
				{:ok, filename}
			some ->
				{:error, "cannot get pic, http resp #{inspect some}"}
		end
	end

end
