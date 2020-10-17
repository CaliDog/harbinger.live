require Logger

defmodule Harbinger.Worker do
  use GenServer

  @server "https://mainnet.smartpy.io/"

  @oracle_contract "KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9"

  @map_get_endpoint "/chains/main/blocks/head/context/contracts/#{@oracle_contract}/big_map_get"

  @request_url "#{@server}#{@map_get_endpoint}"

  @pairs [
    "ZRX-USD", "XTZ-USD", "REP-USD", "LINK-USD",
    "KNC-USD", "ETH-USD", "COMP-USD", "BTC-USD",
    "BAT-USDC", "DAI-USDC",
  ]

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(opts) do
    Logger.info("Async worker starting...")
    {:ok, %{}, {:continue, :continue}}
  end

  defp schedule_callback do
    Logger.debug("Scheduling callback")
    Process.send_after(self(), :tick, 60_000)
  end

  defp pair_request(ticker) do
    %{key: %{string: ticker},
      type: %{prim: "string"}}
  end

  def fetch_data(pair) do
    Logger.info("Fetching data for pair #{pair} from contract #{@oracle_contract}...")

    response = HTTPoison.post!(
      @request_url,
      pair_request(pair) |> Jason.encode!,
      [{"Content-Type", "application/json"}]
    )

    case response do
      %HTTPoison.Response{status_code: 200} = response -> response.body |> Jason.decode!
      _ -> throw("Error: unknown response #{inspect response}")
    end
  end

  defp clean_result(result) do
    %{
      "args" => [
        # start_time: "2020-10-15T06:32:00Z"
        %{"string" => start_time},
        %{
          "args" => [
            # end_time: "2020-10-15T06:33:00Z"
            %{"string" => end_time},
            %{
              "args" => [
                # open: "11407340000"
                %{"int" => open},
                %{
                  "args" => [
                    # high: "11407340000"
                    %{"int" => high},
                    %{
                      "args" => [
                        # low: "11407330000"
                        %{"int" => low},
                        %{
                          "args" => [
                            # close: "11407330000"
                            %{"int" => close},
                            # volume: "169945"
                            %{"int" => volume}
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
            }
          ],
          "prim" => "Pair"
        }
      ],
      "prim" => "Pair"
    } = result

    %{
      start: start_time,
      end: end_time,
      open: open |> String.to_integer,
      high: high |> String.to_integer,
      low: low |> String.to_integer,
      close: close |> String.to_integer,
      volume: volume |> String.to_integer
    }
  end

  def look_for_update(state) do
    @pairs
      |> Enum.map(fn ticker ->
        {ticker, fetch_data(ticker) |> clean_result()}
      end)
      |> Map.new
  end

  def update(state) do
    updated_state = look_for_update(state)

    schedule_callback()

    {:noreply, updated_state}
  end

  def handle_continue(:continue, state) do
    Logger.debug("Handling continue")
    update(state)
  end

  def handle_info(:tick, state) do
    Logger.debug("Tick!")
    update(state)
  end

  def handle_call(:prices, _from, state) do
    {:reply, state, state}
  end

  def prices() do
    GenServer.call(__MODULE__, :prices)
  end

end
