require Logger

defmodule Harbinger.Worker do
  use GenServer

  #@server "https://mainnet.smartpy.io"
  #@server "https://rpc.tzbeta.net"
  @server "https://mainnet-tezos.giganode.io"

  @contracts %{
    "Coinbase Pro" => "KT1AdbYiPYb5hDuEuVrfxmFehtnBCXv4Np7r"
  }

  @contracts_route       "/chains/main/blocks/head/context/contracts/"
  @map_get_endpoint      "/big_map_get"
  @storage_list_endpoint "/storage"

  @default_http_options [timeout: 10_000, recv_timeout: 10_000, ssl: [{:versions, [:'tlsv1.2']}]]

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("Async worker starting...")
    {:ok, %{}, {:continue, :continue}}
  end

  def extract_pairs(response) do
    payload = response.body |> Jason.decode!
    %{
      "args" => [
        %{
          "args" => [
            pairs,
            %{"int" => "101"}
          ],
          "prim" => "Pair"
        },
        %{
          "args" => [
            %{"int" => "6"},
            %{"string" => "KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9"}
          ],
          "prim" => "Pair"
        }
      ],
      "prim" => "Pair"
    } = payload

    pairs
      |> Enum.map(fn x -> x["string"] end)
  end

  def handle_continue(:continue, state) do
    state = @contracts
      |> Enum.map(fn {exchange, normalizer_contract} ->
        response = HTTPoison.get!(@server <> @contracts_route <> normalizer_contract <> @storage_list_endpoint, [], @default_http_options)
        pairs = extract_pairs(response)
                |> Enum.map(fn pair -> {pair, %{}} end)
                |> Map.new
        {exchange, pairs}
      end)
      |> Map.new

    update(state)
  end

  def handle_info(:tick, state) do
    update(state)
  end

  def handle_call(:prices, _from, state) do
    {:reply, state, state}
  end

  defp schedule_callback do
    Logger.debug("Scheduling callback")
    Process.send_after(self(), :tick, 60_000)
  end

  defp pair_request(ticker) do
    %{key: %{string: ticker},
      type: %{prim: "string"}}
  end

  def fetch_data(exchange, pair) do
    Logger.info("Fetching data for pair #{pair} from contract #{@contracts[exchange]}...")

    response = HTTPoison.post!(
      @server <> @contracts_route <> @contracts[exchange] <> @map_get_endpoint,
      pair_request(pair) |> Jason.encode!,
      [{"Content-Type", "application/json"}],
      @default_http_options
    )

    case response do
      %HTTPoison.Response{status_code: 200} = response ->
        response.body
          |> Jason.decode!
      _ -> throw("Error: unknown response #{inspect response}")
    end
  end

  defp clean_result(result) do
    %{
      "args" => [
        %{
          "args" => [%{"int" => computed_price}, %{"string" => last_update_time}],
          "prim" => "Pair"
        },
        %{
          "args" => [
            %{
              "args" => [
                %{
                  "args" => [%{"int" => _}, %{"int" => _}],
                  "prim" => "Pair"
                },
                %{
                  "args" => [
                    [
                      %{
                        "args" => [%{"int" => _}, %{"int" => price_1}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => price_2}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => price_3}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => price_4}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => price_5}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => price_6}],
                        "prim" => "Elt"
                      }
                    ],
                    %{"int" => price_sum}
                  ],
                  "prim" => "Pair"
                }
              ],
              "prim" => "Pair"
            },
            %{
              "args" => [
                %{
                  "args" => [%{"int" => _}, %{"int" => _}],
                  "prim" => "Pair"
                },
                %{
                  "args" => [
                    [
                      %{
                        "args" => [%{"int" => _}, %{"int" => volume_1}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => volume_2}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => volume_3}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => volume_4}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => volume_5}],
                        "prim" => "Elt"
                      },
                      %{
                        "args" => [%{"int" => _}, %{"int" => volume_6}],
                        "prim" => "Elt"
                      }
                    ],
                    %{"int" => volume_total}
                  ],
                  "prim" => "Pair"
                }
              ],
              "prim" => "Pair"
            }
          ],
          "prim" => "Pair"
        }
      ],
      "prim" => "Pair"
    } = result

    %{
      lastUpdate: last_update_time,
      computedPrice: computed_price |> String.to_integer,
      priceHistory: [price_1, price_2, price_3, price_4, price_5, price_6] |> Enum.map(&String.to_integer/1),
      volumeHistory: [volume_1, volume_2, volume_3, volume_4, volume_5, volume_6] |> Enum.map(&String.to_integer/1),
      priceSum: price_sum
    }
  end

  def look_for_update(state) do
    state
      |> Enum.map(fn {exchange, pairs} ->
        pair_data =
          pairs
          |> Enum.map(fn {ticker, _} ->
            {ticker, fetch_data(exchange, ticker)
                        |> clean_result()}
          end)
          |> Map.new
        {exchange, pair_data}
      end)
      |> Map.new
  end

  def update(state) do
    updated_state = look_for_update(state)

    Harbinger.SocketHandler.broadcast_message(%{type: "oracleDataUpdate", state: updated_state} |> Jason.encode!)

    schedule_callback()

    {:noreply, updated_state}
  end

  def prices() do
    GenServer.call(__MODULE__, :prices)
  end

end
