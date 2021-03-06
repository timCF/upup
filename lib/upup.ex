defmodule Upup do
  use Application
  use Silverb, [
	  {"@proxy_ttl",:timer.minutes(1)},
	  {"@proxy_cache",:timer.minutes(60)},
	  {"@phantom_ttl", :timer.minutes(5)},
	  {"@smart_memo_ttl", :timer.minutes(5)}
  ]
  use Logex, [ttl: 100]
  require Exutils

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

	# tmp dir for pics from web
	tmpdir = Exutils.priv_dir(:upup)<>"/tmp"
	_ = File.rm_rf(tmpdir)
	_ = File.mkdir(tmpdir)

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Upup.Worker, [arg1, arg2, arg3]),
	  worker(Upup.Starter, []),
	  worker(Upup.Proxy, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Upup.Supervisor]
    Supervisor.start_link(children, opts)
  end


	def getproxy(country) do
		case Tinca.WeakLinks.get(:proxy_whitelist_content) do
			lst = [_|_] -> Enum.random(lst)
			_ -> case Tinca.memo(&get_proxy_process/1, [country], @proxy_ttl) |> Enum.shuffle do
					[] -> nil
					lst = [el|_] ->
						case Enum.filter(lst, &(Tinca.WeakLinks.get({:proxy_whitelist, &1}) == true)) do
							[] -> el
							lst = [el|_] ->
								Tinca.WeakLinks.make(:proxy_whitelist_content, lst, @proxy_cache)
								el
						end
				end
		end
	end

	def get_proxy_process(_, attempt \\ 0)
	def get_proxy_process(country, attempt) when (attempt < 10) do
		dir2exec = Exutils.priv_dir(:upup)<>"/fproxy"
		case System.cmd("#{dir2exec}/run.sh", [country], [stderr_to_stdout: true, cd: dir2exec]) |> elem(0) |> to_string |> Jazz.decode! |> Exutils.safe(@phantom_ttl) do
			proxylist = [_|_] -> proxylist
			some ->
				Upup.error("error on getting proxy, got #{inspect some}")
				:timer.sleep(1000)
				get_proxy_process(country, attempt + 1)
		end
	end
	def get_proxy_process(_,_), do: []

	def get_permissions(token, proxy), do: Tinca.smart_memo(&Exvk.Auth.get_permissions/2, [token,proxy], &is_integer/1, @smart_memo_ttl)
	def get_my_name(token, proxy), do: Tinca.smart_memo(&Exvk.Auth.get_my_name/2, [token,proxy], &is_map/1, @smart_memo_ttl)

end
