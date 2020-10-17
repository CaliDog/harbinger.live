defmodule Harbinger.Router do
  use Plug.Router

  plug Plug.Static,
       at: "/",
       from: "../dist/"
  plug :match
  plug Plug.Parsers,
       parsers: [:json],
       pass: ["application/json"],
       json_decoder: Jason

  plug :dispatch

  @index_template File.read!("../dist/index.html")

  get "/" do
    response = EEx.eval_string(@index_template, assigns: [context: get_init_state()])
    send_resp(conn, 200, response)
  end

  match _ do
    send_resp(conn, 404, "404")
  end

  def get_init_state() do
    Jason.encode!(%{
      prices: Harbinger.Worker.prices,
      connected_count: Registry.count(Registry.ClientMessageBus),
    })
  end
end
