defmodule CosmosodysseyWeb.RouteController do
  use CosmosodysseyWeb, :controller

  alias Cosmosodyssey.Repo
  alias Cosmosodyssey.Data.Provider
  alias CosmosodysseyWeb.SearchController

  defp filter_providers(route_and_providers, company) do
    # filter providers by company
    route_and_providers |> Enum.map(fn {from_to, providers} ->
      {from_to, Enum.filter(providers, fn provider -> provider.provider.company == company end)}
    end)
  end

  defp order_providers(route_and_providers, params \\ %{}) do
    # order providers by a field and either in desc or asc order
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

  defp get_sorted_indexes(ids) do
    # all params have indexes to know their order, but these indexes must be subtracted out of the param
    id_indexes = ids |> Enum.map(fn{param_name, id} ->
      # the param is in the form "booking_opt_#", where we only need the last # as an integer
      {idx_int, _} = Integer.parse(List.last(String.split(param_name, "_")))
      {idx_int, id}
    end)
    # sort the indexes to know in which order the providers are in according to the route
    id_indexes |> List.keysort(0)
  end

  defp get_chronological_validity(provider_pairs) do
    # check if all providers are chronologically in order
    provider_pairs = sorted |> Enum.map(fn{_, id} ->
      provider = Repo.get!(Provider, id)
    end) |> Enum.chunk_every(2, 1, :discard) # chunk them in groups of 2 so we can compare their end and start times
    provider_pairs |> Enum.map(fn [provider1, provider2]->
      {:ok, parsed_end_time} = SearchController.string_to_datetime(provider1.end_time)
      {:ok, parsed_start_time} = SearchController.string_to_datetime(provider2.start_time)
      Timex.before?(parsed_end_time, parsed_start_time)
    end)
  end

  def index(conn, %{"from" => from, "to" => to}) do
    # function for resetting the filter selections
    case SearchController.get_valid_price_list() do
      {:ok, pl} ->
        {providers, pairs} = SearchController.get_providers(pl.id, from, to)
        render(conn, "index.html", providers: providers, routes: pairs, pickup_planet: from, dropoff_planet: to)
      {:error, nil} -> conn
                       |> put_flash(:error, "Price list expired during booking process. Please search again!")
                       |> redirect(to: Routes.page_path(conn, :index))
      end
  end

  def index(conn, %{"book" => params}) do
    # on booking button click, sends selected options to booking controller
    # get all passed parameters
    from = get_in(params, ["from"])
    to = get_in(params, ["to"])
    # since Phoenix does not allow to pass lists as params, we concatenated them into a string in the template and now have to split them again
    routes = String.split(get_in(params, ["routes"]), "-")
    route_no = get_in(params, ["route_no"])
    # filter out provider ID-s from the params
    ids = params |> Enum.filter(fn {param_name, _} ->
      String.starts_with?(param_name, "booking_opt_")
    end)
    {route_no_int, _} = Integer.parse(route_no)
    # check that the required number of providers was selected in order to make booking
    case route_no_int == length(ids) do
      false ->
        case SearchController.get_valid_price_list() do
          {:ok, pl} ->
            {providers, pairs} = SearchController.get_providers(pl.id, from, to)
            conn
            |> put_flash(:error, "Please choose a trip in all subroutes!")
            |> render("index.html", providers: providers, routes: pairs, pickup_planet: from, dropoff_planet: to)
          {:error, nil} -> conn
                           |> put_flash(:error, "Price list expired during booking process. Please search again!")
                           |> redirect(to: Routes.page_path(conn, :index))
        end
      true ->
        # get sorted indexes, then get providers in the correct order with those indexes
        sorted = get_sorted_indexes(ids)
        # check if the selected trips are in chronological order
        is_valid = get_chronological_validity(sorted)
        case SearchController.get_valid_price_list() do
          {:ok, pl} ->
            {providers, pairs} = SearchController.get_providers(pl.id, from, to)
            # if there is a false in is_valid, then there exists dates that are in incorrect order
            case Enum.member?(is_valid, false) do
              true ->
                conn
                |> put_flash(:error, "Please choose trips that are in chronological order!")
                |> render("index.html", providers: providers, routes: pairs, pickup_planet: from, dropoff_planet: to)
              false ->
                # Phoenix does not allow to pass complex maps or lists as params, so extract the ids as a simple list
                ids = id_indexes |> Enum.map(fn {_, id} -> id end)
                conn
                |> redirect(to: Routes.booking_path(conn, :new, providers: ids, routes: pairs, from: from, to: to))
            end
          {:error, nil} ->
            conn
             |> put_flash(:error, "Price list expired during booking process. Please search again!")
             |> redirect(to: Routes.page_path(conn, :index))
        end
    end
  end

  def index(conn, %{"filter" => filter_params, "order_by" => order_by}) do
    # on filter button click, sends selected filtered/ordered providers to template
    # extract params
    company = get_in(filter_params, ["company"])
    from = get_in(filter_params, ["from"])
    to = get_in(filter_params, ["to"])
    case SearchController.get_valid_price_list() do
      {:error, nil} -> conn
                       |> put_flash(:error, "Price list expired during booking process. Please search again!")
                       |> redirect(to: Routes.page_path(conn, :index))
      {:ok, pl} ->
        {providers, pairs} = SearchController.get_providers(pl.id, from, to)
        # check all cases (and act accordingly):
        #   if filter exists and order_by not
        #   if filter exists and order_by as well
        #   if filter doesn't exist and order_by does
        #   if neither filter or order_by exist
        case company != nil && company != "" do
          true ->
            filtered = filter_providers(providers, company)
            case order_by != nil && order_by != "" do
              true ->
                ordered = order_providers(filtered, order_by)
                render(conn, "index.html", providers: ordered, routes: pairs, pickup_planet: from, dropoff_planet: to)
              false ->
                render(conn, "index.html", providers: filtered, routes: pairs, pickup_planet: from, dropoff_planet: to)
            end
          false ->
            case order_by != nil && order_by != "" do
              true ->
                ordered = order_providers(providers, order_by)
                render(conn, "index.html", providers: ordered, routes: pairs, pickup_planet: from, dropoff_planet: to)
              false ->
                render(conn, "index.html", providers: providers, routes: pairs, pickup_planet: from, dropoff_planet: to)
            end
        end
    end
  end
end
