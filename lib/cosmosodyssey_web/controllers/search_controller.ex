defmodule CosmosodysseyWeb.SearchController do
  use CosmosodysseyWeb, :controller
  import Ecto.Query

  alias Cosmosodyssey.Repo
  import Ecto.Query
  alias Ecto.Changeset
  alias Cosmosodyssey.Data.{Provider, PriceList, Route}

  def string_to_datetime(datetime) do
    Timex.parse(datetime, "{ISO:Extended:Z}")
  end

  defp add_routes_providers(price_list_json) do
    # add the newest price list to repo
    price_list_to_add = PriceList.changeset(%PriceList{}, %{id: price_list_json["id"], valid_until: price_list_json["validUntil"]})
    added_price_list = update_15_price_lists(price_list_to_add)

    # add all routes to repo
    routes = price_list_json["legs"]
    Enum.each routes, fn(route) ->
      route_info = route["routeInfo"]
      route_struct = Ecto.build_assoc(added_price_list, :routes,
        %{id: route_info["id"],
          dropoff_planet: route_info["to"]["name"],
          pickup_planet: route_info["from"]["name"],
          distance: route_info["distance"]})
      extracted_route = Repo.insert!(Route.changeset(route_struct, %{}))

      # add all providers tied to the route to repo
      provider_info = route["providers"]
      Enum.each provider_info, fn(provider) ->
        provider_struct = Ecto.build_assoc(extracted_route, :providers,
          %{id: provider["id"],
            start_time: provider["flightStart"],
            end_time: provider["flightEnd"],
            price: provider["price"],
            company: provider["company"]["name"]})
        Repo.insert!(Provider.changeset(provider_struct, %{}))
      end
    end
    # return the price list that has all of the added information
    added_price_list
  end

  defp sort_by_validity(price_lists) do
    # filter out price lists that are valid, should return list of length 1
    Enum.filter(price_lists, fn price_list ->
      {:ok, parsed_valid_until} = string_to_datetime(price_list.valid_until)
      Timex.before?(Timex.now(), parsed_valid_until) #valid_until should be before current datetime
    end)
  end

  def get_valid_price_list() do
    # get the latest price list that's valid, starting by querying all price lists
    query = from(pl in PriceList)
    price_lists = Repo.all(query)
    valid_pls = sort_by_validity(price_lists)
    case length(valid_pls) == 0 do
      true -> {:error, nil}
      false -> {:ok, List.first(valid_pls)}
    end
  end

  defp update_15_price_lists(price_list_to_add) do
    # add new price list to repo and limit price lists to 15
    query = from(pl in PriceList)
    sorted_price_lists = Repo.all(query) |> Enum.sort( fn (pl1, pl2) ->
      {:ok, parsed_pl1_valid_until} = string_to_datetime(pl1.valid_until)
      {:ok, parsed_pl2_valid_until} = string_to_datetime(pl2.valid_until)
      Timex.compare( parsed_pl1_valid_until, parsed_pl2_valid_until ) >= 0
    end)
    if length(sorted_price_lists) == 15 do
      Logger.warn "deleting older pl due to 15 limit"
      Repo.delete!(List.last(sorted_price_lists))
    end
    Repo.insert!(price_list_to_add)
  end

  defp fetch_data() do
    # fetch JSON from API
    url = "https://cosmos-odyssey.azurewebsites.net/api/v1.0/TravelPrices"
    response = HTTPoison.get(url)
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # decode JSON and see if the latest price list is already in database
        {:ok, price_list_json} = Poison.decode(body)
        price_list = Repo.get(PriceList, price_list_json["id"])
        case price_list == nil do
          true -> # add the new price list
            added_price_list = add_routes_providers(price_list_json)
            {:ok, added_price_list}
          false -> {:ok, "Nothing added from API"} # no new price list from API
        end
      _ -> response
    end
  end

  def get_duration(start_time, end_time) do
    # parse strings into DateTime objects, then return the difference between them in days
    {:ok, parsed_start_time} = string_to_datetime(start_time)
    {:ok, parsed_end_time} = string_to_datetime(end_time)
    Timex.diff(parsed_end_time, parsed_start_time, :days)
  end

  defp format_datetimes(provider) do
    # parse string datetimes to DateTime object
    {:ok, parsed_start_time} = string_to_datetime(provider.start_time)
    {:ok, parsed_end_time} = string_to_datetime(provider.end_time)
    # format datetime
    {:ok, formatted_start_time} = Timex.format(parsed_start_time, "{WDshort}, {D} {Mshort} {YYYY}, {h24}:{m}")
    {:ok, formatted_end_time} = Timex.format(parsed_end_time, "{WDshort}, {D} {Mshort} {YYYY}, {h24}:{m}")

    # apply changes and return the updated provider
    changeset = Changeset.cast(provider, %{start_time: formatted_start_time, end_time: formatted_end_time}, [:start_time, :end_time])
    Changeset.apply_changes(changeset)
  end

  def get_providers(price_list_id, from, to) do
    # get providers for the shortest possible route between the selected planets
    possible_route = get_shortest_route_from_to(from, to)
    pairs = Enum.chunk_every(possible_route, 2, 1, :discard) # create pairs of planets

    providers_of_route_pairs = pairs |> Enum.map(fn [from, to] ->
      providers = from(pl in PriceList,
                join: r in Route,
                join: p in Provider,
                on:
                  pl.id == r.price_list_id and
                  r.id == p.route_id,
                where:
                  pl.id == ^price_list_id and
                  r.dropoff_planet == ^to and
                  r.pickup_planet == ^from,
                select: %{
                  provider: p,
                  distance: r.distance,
                })
               |> Repo.all()
      case length(providers) == 0 do
        true -> nil # if at least one of subroutes has no providers, then this whole route is unsuitable
        false ->
          providers |> Enum.map(fn provider ->
            duration = get_duration(provider.provider.start_time, provider.provider.end_time)
            %{distance: provider.distance,
              provider: provider.provider,
              duration: duration}
          end)
      end
    end)
    case Enum.member?(providers_of_route_pairs, nil) || length(providers_of_route_pairs) != length(pairs) do
      true -> nil
      false ->
        {Enum.zip(pairs, providers_of_route_pairs), pairs} # zip together the subroute and its' providers
    end
  end

  def get_shortest_route_from_to(from, to) do
    # get all current routes
    query = from(pl in Route)
    routes = Repo.all(query)
    # create a graph and run the dijkstra algorithm on it to find the shortest route
    graph = CosmosodysseyWeb.Graph.into_graph(routes)
    CosmosodysseyWeb.Graph.shortest_path(graph, from, to)
  end

  def search(conn, %{"pickup_planet" => pickup_planet, "dropoff_planet" => dropoff_planet} = _params) do
    case pickup_planet == "" || dropoff_planet == "" do
      true ->
        conn
        |> put_flash(:error, "Please enter both a pick-up and drop-off planet!")
        |> redirect(to: Routes.page_path(conn, :index))
      false ->
        # capitalize planet names for ease of search
        pickup_planet = String.capitalize(pickup_planet)
        dropoff_planet = String.capitalize(dropoff_planet)
        planets = ["Mercury", "Earth", "Venus", "Jupiter", "Mars", "Saturn", "Neptune", "Uranus"]
        # check if entered planets are valid
        case Enum.member?(planets, pickup_planet) && Enum.member?(planets, dropoff_planet) do
          false ->
            conn
            |> put_flash(:error, "Please enter planets from our solar system!")
            |> redirect(to: Routes.page_path(conn, :index))
          true ->
            price_list = get_valid_price_list()
            Logger.warn inspect price_list
            case price_list do
              {:error, nil} ->
                # no valid price list was found, so fetch API for new one (if exists)
                response = fetch_data()
                case response do
                  {:ok, %HTTPoison.Response{status_code: 404}} ->
                    conn
                    |> put_flash(:error, "Could not access price list API. Try again later!")
                    |> redirect(to: Routes.page_path(conn, :index))
                  {:error, %HTTPoison.Error{reason: reason}} ->
                    conn
                    |> put_flash(:error, "Error fetching price list API: #{reason}")
                    |> redirect(to: Routes.page_path(conn, :index))
                  {:ok, "Nothing added from API"} ->
                    conn
                    |> put_flash(:error, "No valid routes available!")
                    |> redirect(to: Routes.page_path(conn, :index))
                  {:ok, added_price_list} ->
                    # presume API doesn't send erroneous non-valid data
                    {providers, pairs} = get_providers(added_price_list.id, pickup_planet, dropoff_planet)
                    case providers == nil do
                      true ->
                        conn
                        |> put_flash(:error, "No trips between those two planets found.")
                        |> redirect(to: Routes.page_path(conn, :index))
                      false ->
                        render conn, "results.html", providers: providers, routes: pairs, pickup_planet: pickup_planet, dropoff_planet: dropoff_planet
                    end
                end
              {:ok, price_list} ->
                {providers, pairs} = get_providers(price_list.id, pickup_planet, dropoff_planet)
                case providers == nil do
                  true ->
                    conn
                    |> put_flash(:error, "No trips between those two planets found.")
                    |> redirect(to: Routes.page_path(conn, :index))
                  false ->
                    render conn, "results.html", providers: providers, routes: pairs, pickup_planet: pickup_planet, dropoff_planet: dropoff_planet
                end
            end
        end
    end
  end
end
