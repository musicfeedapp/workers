defmodule Requesters.Mixfile do
  use Mix.Project

  def project do
    [app: :requesters,
     version: "0.12.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :getopt,
        :logger,
        :xmerl,
        :tzdata,
        :providers,
        :tirexs,
        :httpoison,
        :timex_ecto,
        :lager_logger,
        :connection,
        :postgrex,
        :amqp,
        :rabbit_common,
        :edeliver,
        :floki,
        :retry,
        :exredis,
        :poison,
        :redis_poolex,
        # Remote shell:
        # epmd -names
        # ssh -N -L 4369:localhost:4369 -L 41533:localhost:41533 root@music-api
        # erl -name requesters@127.0.0.1 -hidden -run observer
        :runtime_tools,
      ],
      mod: {Requesters, []},
      erl_opts: [parse_transform: "lager_transform"],
    ]
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
      {:redis_poolex, github: "oivoodoo/redis_poolex"},
      {:httpoison, "~> 1.1.0"},
      {:poison, "~> 2.2"},
      {:hackney, "~> 1.12.0"},
      {:poolboy, ">= 1.5.1"},
      {:timex, "~> 2.2.1"},
      {:timex_ecto, "~> 1.1.3"},

      {:providers, github: "tsloughter/providers", override: true},
      {:getopt, github: "jcomellas/getopt", override: true},

      {:edeliver, "~> 1.4"},
      {:distillery, ">= 0.9.0", warn_missing: false},

      {:floki, "~> 0.15"},
      {:postgrex, "0.13.5"},

      {:mochiweb, github: "oivoodoo/mochiweb", override: true},

      {:amqp, github: "pma/amqp"},

      {:ecto, "~> 2.2.10"},
      {:retry, "~> 0.2.0"},

      {:lager, ">= 2.1.0", [env: :prod, hex: :lager, override: true]},
      {:lager_logger, github: "PSPDFKit-labs/lager_logger", override: true},

      {:tirexs, "~> 0.8"},
    ]
  end
end
