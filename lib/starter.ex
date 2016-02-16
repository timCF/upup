defmodule Upup.Starter do
	use ExActor.GenServer
	use Silverb, [
		{"@ttl", :timer.seconds(30)}
	]
	definit do
		{:ok, nil, 1}
	end
	definfo :timeout do
		Upup.Storage.get_active_accounts
		|> Enum.each(fn(%Upup.Account{uid: uid}) ->
			thread = "upup_#{Integer.to_string(uid)}" |> String.to_atom
			if not(:erlang.whereis(thread) |> is_pid) do
				{:ok, pid} = :supervisor.start_child(Upup.Supervisor, Supervisor.Spec.worker(Upup.Worker, [uid], [id: thread, name: thread, restart: :temporary]))
				true = is_pid(pid)
				true = :erlang.register(thread, pid)
			end
		end)
		{:noreply, nil, @ttl}
	end
end
