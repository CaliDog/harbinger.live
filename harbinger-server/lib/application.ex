defmodule Harbinger do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: nil,
        options: [
          dispatch: dispatch(),
          port: System.get_env("PORT", "4000")
                |> String.to_integer
        ]
      ),
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.ClientMessageBus
      ),
      Harbinger.Worker
    ]

    opts = [strategy: :one_for_one, name: Harbinger.Application]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
        [
          {"/ws/", Harbinger.SocketHandler, []},
          {:_, Plug.Cowboy.Handler, {Harbinger.Router, []}}
        ]
      }
    ]
  end
end
