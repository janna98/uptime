defmodule CosmosodysseyWeb.Graph do

  require Logger
  alias Graph.Edge

  def into_graph(routes) do
    edges = Enum.map routes, fn (route) ->
      Edge.new(route.pickup_planet, route.dropoff_planet, weight: route.distance)
    end
    Graph.new(type: :directed) |> Graph.add_vertices(["Mercury", "Earth", "Venus", "Jupiter", "Mars", "Saturn", "Neptune", "Uranus"]) |> Graph.add_edges(edges)
  end

  def shortest_path(graph, from, to) do
    Graph.dijkstra(graph, from, to)
  end
end
