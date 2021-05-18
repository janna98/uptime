defmodule CosmosodysseyWeb.BookingController do
  use CosmosodysseyWeb, :controller

  require Logger
  alias Cosmosodyssey.Data.{Booking, Provider, Route}
  alias Cosmosodyssey.Accounts.User
  alias Cosmosodyssey.Repo
  import Ecto.Query

  defp get_current_user(conn) do
    Repo.get!(User, Guardian.Plug.current_resource(conn).id)
  end

  def format_single_datetime(datetime) do
    {:ok, parsed_time} = Timex.parse(datetime, "{ISO:Extended:Z}")
    {:ok, formatted_time} = Timex.format(parsed_time, "{WDshort}, {D} {Mshort} {YYYY}, {h24}:{m}")
    formatted_time
  end

  def index(conn, _params) do
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
    # xd = Enum.reduce random_routes, %{}, fn {details}, acc ->
    #  Logger.warn "details #{inspect details}"
    #  duration = get_duration(details.provider.start_time, details.provider.end_time)
    #  Map.put(acc, "companies", [details.provider.company | acc.companies])
    #  Map.put(acc, "price", acc.price + details.provider.price)
    #  Map.put(acc, "duration", acc.duration + duration)
    #  Map.put(acc, "distance", acc.distance + details.distance)
    #  Logger.warn "accumulator: #{inspect acc}"
    #  acc
    #end
    provider = Repo.get!(Provider, provider_id)
    render(conn, "new.html", provider: provider, from: from, to: to, time: time)
  end

  def create(conn, %{"id" => provider_id, "time" => time}) do
    provider = Repo.get!(Provider, provider_id)
    changeset = Booking.changeset(%Booking{}, %{status: "open", travel_time: time})
                |> Ecto.Changeset.put_assoc(:provider, provider)
                |> Ecto.Changeset.put_assoc(:user, get_current_user(conn))
    case Repo.insert(changeset) do
      {:ok, booking} ->
        conn
        |> put_flash(:info, "Booking #{booking.id} successfully created!")
        |> redirect(to: Routes.page_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Booking creation failed!")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
