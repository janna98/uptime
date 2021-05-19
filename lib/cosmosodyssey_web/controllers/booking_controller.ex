defmodule CosmosodysseyWeb.BookingController do
  use CosmosodysseyWeb, :controller

  alias Cosmosodyssey.Data.{Booking, Provider, Route}
  alias Cosmosodyssey.Accounts.User
  alias Cosmosodyssey.Repo
  import Ecto.Query

  defp get_current_user(conn) do
    Repo.get!(User, Guardian.Plug.current_resource(conn).id)
  end

  def format_single_datetime(datetime) do
    # format a single string datetime into a readable time format
    {:ok, parsed_time} = Timex.parse(datetime, "{ISO:Extended:Z}")
    {:ok, formatted_time} = Timex.format(parsed_time, "{WDshort}, {D} {Mshort} {YYYY}, {h24}:{m}")
    formatted_time
  end

  def index(conn, _params) do
    # queries all bookings this user has
    user_id = get_current_user(conn).id
    bookings = from(
                 b in Booking,
                 join: p in Provider,
                 join: r in Route,
                 on:
                   b.provider_id == p.id and
                   r.id == p.route_id,
                 where:
                   b.user_id == ^user_id,
                 select: %{
                   booking: b,
                   route: r,
                   provider: p
                 })
                |> Repo.all()
    render(conn, "index.html", bookings: bookings)
  end

  def new(conn, %{"provider" => provider_id, "from" => from, "to" => to, "time" => time}) do
    # function for confirming a booking with a single provider
    # query that provider and send it to template
    provider = Repo.get!(Provider, provider_id)
    render(conn, "new.html", provider: provider, from: from, to: to, time: time)
  end

  def new(conn, %{"providers" => provider_ids, "routes" => routes, "from" => from, "to" => to}) do
    # function for confirming a booking with a multiple providers and routes
    # query those providers and distances
    providers_and_distances = provider_ids |> Enum.map(fn id ->
      from(p in Provider,
        join: r in Route,
        on:
          r.id == p.route_id,
        where:
          p.id == ^id,
        select: %{
          provider: p,
          distance: r.distance,
        })
      |> Repo.all()
    end)
    # condense info down with an accumulator to get:
    #   total price, duration and distance of the trips
    #   all companies providing the trips
    #   all start and end times of trips
    trip_info = Enum.reduce providers_and_distances, %{price: 0, duration: 0, distance: 0, companies: [], times: []}, fn [provider_distance], acc ->
      duration = CosmosodysseyWeb.SearchController.get_duration(provider_distance.provider.start_time, provider_distance.provider.end_time)
      acc = Map.put(acc, :companies, [provider_distance.provider.company | acc.companies])
      acc = Map.put(acc, :price, (acc.price + provider_distance.provider.price))
      acc = Map.put(acc, :duration, (acc.duration + duration))
      acc = Map.put(acc, :times,
        [{provider_distance.provider.start_time, provider_distance.provider.end_time}  | acc.times])
      Map.put(acc, :distance, (acc.distance + provider_distance.distance))
    end
    # also add route info to the accumulator
    trip_info = Map.put(trip_info, :planets, (routes |> List.flatten |> Enum.uniq))
    render(conn, "new.html", trip_info: trip_info, ids: provider_ids, from: from, to: to, routes: routes)
  end

  def create(conn, %{"id" => provider_id, "time" => time}) do
    # create a single booking
    # query the provider and user in order to make n - m associations in database
    provider = Repo.get!(Provider, provider_id)
    changeset = Booking.changeset(%Booking{}, %{status: "open", travel_time: time})
                |> Ecto.Changeset.put_assoc(:provider, provider)
                |> Ecto.Changeset.put_assoc(:user, get_current_user(conn))
    case Repo.insert(changeset) do
      {:ok, booking} ->
        conn
        |> put_flash(:info, "Booking #{booking.id} successfully created!")
        |> redirect(to: Routes.page_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Booking creation failed!")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def create(conn, %{"ids" => provider_ids, "time" => time}) do
    # create multiple bookings
    # since Phoenix does not allow to pass lists as params, we concatenated them into a string in the template and now have to split them again
    ids = String.split(provider_ids, ",")
    bookings = ids |> Enum.map(fn id ->
      provider = Repo.get!(Provider, id)
      changeset = Booking.changeset(%Booking{}, %{status: "open", travel_time: time})
                  |> Ecto.Changeset.put_assoc(:provider, provider)
                  |> Ecto.Changeset.put_assoc(:user, get_current_user(conn))
      case Repo.insert(changeset) do
        {:ok, booking} -> booking.id #return only ID-s for user response
        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Booking creation failed!")
          |> redirect(to: Routes.page_path(conn, :index))
      end
    end)
    conn
    |> put_flash(:info, "Bookings with ids #{Enum.join(bookings, ", ")} successfully created!")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
