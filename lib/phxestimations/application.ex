defmodule Phxestimations.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhxestimationsWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:phxestimations, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Phxestimations.PubSub},
      # Start a worker by calling: Phxestimations.Worker.start_link(arg)
      # {Phxestimations.Worker, arg},
      # Start to serve requests, typically the last entry
      PhxestimationsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Phxestimations.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhxestimationsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
