defmodule Miosa.MixProject do
  use Mix.Project

  @version "1.2.0"
  @source_url "https://github.com/Miosa-osa/miosa-elixir"

  def project do
    [
      app: :miosa,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Miosa",
      source_url: @source_url,
      dialyzer: [
        plt_add_apps: [:ex_unit],
        flags: [:error_handling, :underspecs]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Miosa.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:finch, "~> 0.21"},
      {:jason, "~> 1.4"},
      {:gun, "~> 2.1"},
      # Dev/test
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:bypass, "~> 2.1", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test}
    ]
  end

  defp description do
    "Official Elixir SDK for MIOSA — cloud computers for AI agents. Desktop control, file operations, sandboxes, deployments, databases, and more."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/miosa"
      },
      maintainers: ["MIOSA AI"],
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md"],
      groups_for_modules: [
        Core: [Miosa, Miosa.Client],
        Resources: [
          Miosa.Computers,
          Miosa.Computer,
          Miosa.Computer.Agent,
          Miosa.Sandboxes,
          Miosa.Sandbox.Processes,
          Miosa.Desktop,
          Miosa.Agent,
          Miosa.Files,
          Miosa.Exec,
          Miosa.Exec.Command,
          Miosa.Credits,
          Miosa.Admin,
          Miosa.Workspaces,
          Miosa.Checkpoints,
          Miosa.Services,
          Miosa.CustomDomains,
          Miosa.Events,
          Miosa.NetworkPolicy
        ],
        OpenComputers: [
          Miosa.OpenComputers,
          Miosa.OpenComputers.Hosts,
          Miosa.OpenComputers.Jobs,
          Miosa.OpenComputers.Fs,
          Miosa.OpenComputers.Terminal,
          Miosa.OpenComputers.DesktopVnc,
          Miosa.OpenComputers.Tunnels,
          Miosa.OpenComputers.Agents,
          Miosa.OpenComputers.Clusters,
          Miosa.OpenComputers.Secrets
        ],
        Egress: [
          Miosa.Secrets,
          Miosa.Network,
          Miosa.Audit,
          Miosa.OauthFlow,
          Miosa.Sandboxes.Secrets,
          Miosa.Sandboxes.Network,
          Miosa.Sandboxes.Audit
        ],
        Types: [Miosa.Types],
        Errors: [Miosa.Error]
      ]
    ]
  end
end
