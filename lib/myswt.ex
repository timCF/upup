defmodule Upup.Myswt do
	use Silverb, [
		{"@imgregexp", ~r/^http\:\/\/cs\d+\.vk\.me/}
	]
	require Myswt
	Myswt.callback_module do
		def handle_myswt(%Myswt.Proto{subject: "get_account_data", content: %{token: token, country: country}}) when is_binary(token) and is_binary(country) do
			case get_connection_details(token, country) do
				error = %Myswt.Proto{} -> error
				%{first_name: first_name, uid: uid, proxy: _} ->
					tasks = Upup.Storage.get_tasks(uid)
					%Myswt.Proto{
						subject: "get_account_data",
						content: %{
							first_name: first_name,
							tasks: tasks,
							albums: Upup.Storage.get_albums_map(tasks),
							items: Upup.Storage.get_items_map(tasks)
						}
					}
			end
			|> Myswt.encode
		end
		def handle_myswt(%Myswt.Proto{subject: "new_task", content: %{token: token, country: country, data: data = %{task_name: _, ttl: _}}}) do
			case get_connection_details(token, country) do
				error = %Myswt.Proto{} -> error
				%{uid: uid} ->
					case Map.update!(data, :task_name, &Maybe.maybe_to_string/1) |> Map.update!(:ttl, &Maybe.to_integer/1) do
						%{task_name: task_name, ttl: ttl} when (is_binary(task_name) and is_integer(ttl) and (ttl > 0)) ->
							:ok = Upup.Storage.new_tasks([%{uid: uid, task_name: task_name, ttl: ttl}])
							%Myswt.Proto{subject: "notice", content: "задача #{task_name} добавлена"}
						some ->
							%Myswt.Proto{content: "неверные данные #{inspect some}"}
					end
			end
			|> Myswt.encode
		end
		def handle_myswt(%Myswt.Proto{subject: "save_task", content: %{token: token, country: country, id: id, data: data = %{}}}) do
			case get_connection_details(token, country) do
				error = %Myswt.Proto{} -> error
				%{uid: uid} ->
					#
					#	TODO !!!
					#
			end
			|> Myswt.encode
		end
		def handle_myswt(data = %Myswt.Proto{}), do: (%Myswt.Proto{content: "неверный запрос #{inspect data}"} |> Myswt.encode)
	end

	defp get_connection_details(token, country) do
		case Upup.getproxy(country) do
			nil -> %Myswt.Proto{content: "cannot get proxy for country #{country}"}
			proxy ->
				case Exvk.Auth.get_permissions(token, proxy) do
					2079998 ->
						case Exvk.Auth.get_my_name(token, proxy) do
							{:error, error} -> %Myswt.Proto{content: "cannot get account details for token, error #{inspect error}"}
							%{first_name: name, uid: uid} ->
								:ok = Upup.Storage.save_account(%{uid: uid, country: country, token: token})
								%{first_name: name, uid: uid, proxy: proxy}
						end
					_ ->
						%Myswt.Proto{content: "wrong application token, access denied!"}
				end
		end
	end

end
