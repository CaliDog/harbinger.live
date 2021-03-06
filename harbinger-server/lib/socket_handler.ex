require Logger

defmodule Harbinger.SocketHandler do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    {:cowboy_websocket, request, request}
  end

  def websocket_init(state) do
    Registry.ClientMessageBus
      |> Registry.register("broadcast", {})

    Logger.info("New client connected #{state.headers["cf-connecting-ip"]} - #{state.headers["cf-ipcountry"]} - #{state.headers["user-agent"]}")

    {:ok, state}
  end

  def websocket_handle({:text, "."}, state) do
    {:ok, state}
  end

  def websocket_handle({:text, text}, state) do
    Logger.info("Unknown data recv - #{text}")
    {:ok, state}
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end

  def broadcast_message(message) do
    Registry.ClientMessageBus
    |> Registry.dispatch("broadcast", fn(entries) ->
      for {pid, _} <- entries do
        if pid != self() do
          Process.send(pid, message, [])
        end
      end
    end)
  end

  def terminate(_reason, _partial_req, state) do
    Logger.info("Client disconnected #{state.headers["cf-connecting-ip"]} - #{state.headers["cf-ipcountry"]} - #{state.headers["user-agent"]}")
    :ok
  end

end
