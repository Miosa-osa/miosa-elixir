defmodule Miosa.Application do
  @moduledoc false
  # Top-level supervisor for the Miosa SDK. Currently it owns a single
  # named Finch pool — see `Miosa.Client` for why that pool is shared.
  #
  # Starting Finch under an application supervisor (rather than from the
  # first call to `Miosa.Client.new/2`) means the pool is owned by the
  # application process tree, not by whichever test or caller happened
  # to construct the first client. That keeps connections alive for the
  # lifetime of the application and makes the pool reliably shared
  # across processes.

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch,
       name: :miosa_finch_pool,
       pools: %{
         :default => [
           size: 20,
           protocols: [:http2, :http1],
           conn_max_idle_time: 60_000,
           conn_opts: [transport_opts: [timeout: 30_000]]
         ]
       }}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Miosa.Supervisor)
  end
end
