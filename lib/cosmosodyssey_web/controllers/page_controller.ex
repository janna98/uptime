defmodule CosmosodysseyWeb.PageController do
  use CosmosodysseyWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

end
