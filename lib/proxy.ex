defmodule Upup.Proxy do
	use Silverb, [
		{"@ttl", :timer.minutes(1)}
	]
	use ExActor.GenServer, export: true
	require Exutils
	definit do
		{:ok, nil, 5000}
	end
	definfo :timeout do
		case Upup.Storage.get_active_accounts do
			[] -> :ok
			accounts = [_|_] ->
				Enum.group_by(accounts, fn(%Upup.Account{country: country}) -> country end)
				|> Enum.each(fn({country, accounts}) ->
					case Upup.get_proxy_process(country) do
 						[] -> :ok
						proxylst = [_|_] ->
							Enum.each(proxylst, fn(proxy) ->
								%Upup.Account{token: token} = Enum.random(accounts)
								case Exvk.Auth.get_my_name(token, proxy) |> Exutils.safe do
									%{first_name: _, uid: _} -> Tinca.WeakLinks.make({:proxy_whitelist, proxy}, true, @ttl)
									{:error, _} -> :ok
								end
							end)
					end
				end)
		end
		{:noreply, nil, @ttl}
	end
end
