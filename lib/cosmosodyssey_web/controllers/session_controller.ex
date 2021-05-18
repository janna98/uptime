defmodule CosmosodysseyWeb.SessionController do
  use CosmosodysseyWeb, :controller

  alias Cosmosodyssey.Repo
  alias Cosmosodyssey.Accounts.User

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    user = Repo.get_by(User, email: email)
    case Cosmosodyssey.Authentication.check_credentials(user, password) do
      {:ok, _} ->
        conn
        |> Cosmosodyssey.Authentication.login(user)
        |> put_flash(:info, "Welcome #{user.first_name} #{user.last_name}")
        |> redirect(to: Routes.page_path(conn, :index))
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Bad Credentials")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def delete(conn, _params) do
    conn
    |> Cosmosodyssey.Authentication.logout()
    |> put_flash(:info, "User logged out")
    |> redirect(to: Routes.page_path(conn, :index))
  end

end
