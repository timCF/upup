defmodule Upup.Mixfile do
  use Mix.Project

  def project do
    [app: :upup,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications:	[
						:logger,
						:silverb,
						:exvk,
						:myswt,
						:logex,
						:sqlx,
						:wwwest_lite,
						:exrm
					],
     mod: {Upup, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
	[
		{:silverb, github: "timCF/silverb"},
		{:exvk, github: "timCF/exvk"},
		{:myswt, github: "timCF/myswt", branch: "megaweb"},
		{:logex, github: "timCF/logex"},
		{:sqlx, github: "timCF/sqlx"},
		{:wwwest_lite, github: "timCF/wwwest_lite"},
		{:exrm, github: "bitwalker/exrm", tag: "0.19.9", override: true}
	]
  end
end
