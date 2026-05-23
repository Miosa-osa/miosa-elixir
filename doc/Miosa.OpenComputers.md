# `Miosa.OpenComputers`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/open_computers.ex#L1)

OpenComputers API surface — register and control your own machines via MIOSA.

OpenComputers lets you bring your own Mac, Linux, or Windows machine and
control it through the MIOSA API: run commands, manage files, expose HTTP
tunnels, dispatch AI agents, build inference clusters, and manage secrets.

## Entry points

All functions accept a `Miosa.Client.t()` as the first argument:

    client = Miosa.client("msk_u_...")

    # Hosts
    {:ok, resp} = Miosa.OpenComputers.Hosts.list(client)
    {:ok, host} = Miosa.OpenComputers.Hosts.create(client, %{name: "my-mac"})

    # Jobs
    {:ok, job} = Miosa.OpenComputers.Jobs.run(client, host["id"], %{command: "npm test"})

    # Tunnels
    {:ok, tunnel} = Miosa.OpenComputers.Tunnels.create(client, host["id"], %{target_port: 3000})
    IO.puts(tunnel["public_url"])

    # Agents
    {:ok, session} = Miosa.OpenComputers.Agents.dispatch(client, host["id"], %{task: "run tests"})

---

*Consult [api-reference.md](api-reference.md) for complete listing*
