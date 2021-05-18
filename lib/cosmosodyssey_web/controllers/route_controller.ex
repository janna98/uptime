defmodule CosmosodysseyWeb.RouteController do
  use CosmosodysseyWeb, :controller

  alias Cosmosodyssey.Repo
  alias Cosmosodyssey.Data.Route
  alias Cosmosodyssey.Data.PriceList
  alias Cosmosodyssey.Data.Provider
  alias CosmosodysseyWeb.SearchController

  require Logger

  defp filter_providers(route_and_providers, company) do
    route_and_providers |> Enum.map(fn {from_to, providers} ->
      {from_to, Enum.filter(providers, fn provider -> provider.provider.company == company end)}
    end)
  end

  def order_providers(route_and_providers, params \\ %{}) do
    {type, field} = order_by(params)
    if type == nil || field == nil do
      route_and_providers
    end
    case field == :time do
      true ->
        route_and_providers |> Enum.map(fn {from_to, providers} ->
          {from_to, Enum.sort_by(providers, &(&1.duration), type)}
        end)
      false ->
        route_and_providers |> Enum.map(fn {from_to, providers} ->
          {from_to, Enum.sort_by(providers, &(Map.get &1.provider, field), type)}
        end)
    end
  end

  defp order_by("price_asc"), do: {:asc, :price}
  defp order_by("price_desc"), do: {:desc, :price}
  defp order_by("distance_asc"), do: {:asc, :distance}
  defp order_by("distance_desc"), do: {:desc, :distance}
  defp order_by("travel_time_desc"), do: {:desc, :time}
  defp order_by("travel_time_asc"), do: {:asc, :time}
  defp order_by(_), do: {nil, nil}

  def index(conn, %{"from" => from, "to" => to}) do
    case SearchController.get_valid_price_list() do
      {:ok, pl} ->
        providers = SearchController.get_providers(pl.id, from, to)
        render(conn, "index.html", providers: providers, pickup_planet: from, dropoff_planet: to)
      {:error, nil} -> conn
                       |> put_flash(:error, "Price list expired during booking process. Please search again!")
                       |> redirect(to: Routes.page_path(conn, :index))
      end
  end

  def index(conn, %{"book" => params}) do
    Logger.warn "booking"
    conn
    |> redirect(to: Routes.booking_path(conn, :new))
  end

  def index(conn, %{"filter" => filter_params, "order_by" => order_by}) do
    Logger.warn "filtering"
    company = get_in(filter_params, ["company"])
    from = get_in(filter_params, ["from"])
    to = get_in(filter_params, ["to"])
    case SearchController.get_valid_price_list() do
      {:error, nil} -> conn
                       |> put_flash(:error, "Price list expired during booking process. Please search again!")
                       |> redirect(to: Routes.page_path(conn, :index))
      {:ok, pl} ->
        providers = SearchController.get_providers(pl.id, from, to)
        case company != nil && company != "" do
          true ->
            filtered = filter_providers(providers, company)
            case order_by != nil && order_by != "" do
              true ->
                ordered = order_providers(filtered, order_by)
                render(conn, "index.html", providers: ordered, pickup_planet: from, dropoff_planet: to)
              false ->
                render(conn, "index.html", providers: filtered, pickup_planet: from, dropoff_planet: to)
            end
          false ->
            case order_by != nil && order_by != "" do
              true ->
                ordered = order_providers(providers, order_by)
                render(conn, "index.html", providers: ordered, pickup_planet: from, dropoff_planet: to)
              false ->
                render(conn, "index.html", providers: providers, pickup_planet: from, dropoff_planet: to)
            end
        end
    end
  end
end
