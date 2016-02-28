defmodule Upup.Worker do
	use Silverb, [
		{"@ttl", :timer.seconds(30)},
		{"@proxy_whitelist_ttl", :timer.minutes(5)}
	]
	use GenServer
	require Exutils

	def start_link(args), do: GenServer.start_link(__MODULE__, args)

	def init(uid) do
		Upup.notice("start worker #{Integer.to_string(uid)}")
		<<a::32,b::32,c::32>> = :crypto.rand_bytes(12)
		_ = :random.seed(a,b,c)
		{:ok, Upup.Storage.get_account_details(uid), 1}
	end
	def handle_info(:timeout, account = %Upup.Account{country: country, uid: uid}) do
		case Upup.getproxy(country) do
			nil ->
				{:noreply, account, @ttl}
			proxy ->
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
		Upup.warn("terminate worker #{inspect state}, reason #{inspect reason}")
		:ok
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
							message = "ERROR ON UPLOAD USER PHOTOS #{error}"
							Upup.error(message)
							Upup.Storage.update_album(album, message)
					end
			{:error, error} ->
				message = "ERROR ON CLENUP USER PHOTOS #{error}"
				Upup.error(message)
				Upup.Storage.update_album(album, message)
		end
	end

	defp cleanup_user_photos(album = %Upup.Album{gid: gid, aid: aid}, %Upup.Account{token: token, uid: uid}, proxy) do
		fn() ->
			case Exvk.Photos.get(%{gid: gid, aid: aid}, token, proxy) |> Exutils.safe do
				{:error, error} -> {:error, "error on getting photos #{inspect error}"}
				lst when is_list(lst) ->
					Tinca.WeakLinks.make({:proxy_whitelist, proxy}, true, @proxy_whitelist_ttl)
					case Stream.filter_map(lst,
							fn(%{user_id: user_id}) -> user_id == uid end,
							fn(%{pid: pid}) -> pid end) |> Enum.uniq do
						[] -> :ok
						pids = [_|_] ->
							case Stream.map(pids, &(Exvk.Photos.delete(%{gid: gid, pid: &1}, token, proxy) |> Exutils.safe)) |> Enum.filter(&(&1 != :ok)) do
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
					case Exvk.Photos.upload(%{gid: gid, aid: aid, path: filename, caption: caption}, token, proxy) |> Exutils.safe do
						:ok ->
							Tinca.WeakLinks.make({:proxy_whitelist, proxy}, true, @proxy_whitelist_ttl)
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
		case HTTPoison.get(link, [], [hackney: [recv_timeout: 60000, connect_timeout: 60000]]) do
			{:ok, %HTTPoison.Response{status_code: 200, body: bin}} when is_binary(bin) ->
				filename = Exutils.priv_dir(:upup)<>"/tmp/"<>Exutils.make_uuid<>"."<>(String.split(link,".") |> List.last)
				File.write!(filename, bin)
				{:ok, filename}
			some ->
				{:error, "cannot get pic, http resp #{inspect some}"}
		end
	end

end
