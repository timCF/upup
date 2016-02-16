defmodule Upup do
  use Application
  use Silverb
  use Logex, [ttl: 100]

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
	  worker(Upup.Starter, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Upup.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
