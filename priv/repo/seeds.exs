# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Cosmosodyssey.{Repo, Accounts.User, Data.Booking, Data.Route, Data.PriceList, Data.Provider}

# below are the two users that can be used to log into the application
lisa = Repo.insert!(User.changeset(%User{}, %{first_name: "Lisa", last_name: "Simpson", email: "lisa@simpson.com", password: "parool"}))
bart = Repo.insert!(User.changeset(%User{}, %{first_name: "Bart", last_name: "Simpson", email: "bart@simpson.com", password: "parool"}))

# the lines below can be used when API does not respond or fetching is unsuccessful
# in order to have sample data to work with

#price_list = Repo.insert!(PriceList.changeset(%PriceList{}, %{id: "a", valid_until: "2021-10-05T10:46:15.1820247Z"}))

#route_struct = Ecto.build_assoc(price_list, :routes,
#  %{dropoff_planet: "Earth",
#    pickup_planet: "Saturn",
#    distance: 1275000000,
#    id: "a"
#  })
#route1 = Repo.insert!(Route.changeset(route_struct, %{}))
#route_struct = Ecto.build_assoc(price_list, :routes,
#  %{dropoff_planet: "Venus",
#    pickup_planet: "Jupiter",
#    distance: 670130000,
#    id: "b"
#  })
#route2 = Repo.insert!(Route.changeset(route_struct, %{}))
#
#
#provider_struct = Ecto.build_assoc(route1, :providers,
#  %{start_time: "2021-05-17T00:54:15.1820406Z",
#    end_time: "2021-05-22T00:54:15.1820406Z",
#    price: 80819.86,
#    company: "SpaceX",
#    id: "a"
#  })
#provider1 = Repo.insert!(Provider.changeset(provider_struct, %{}))
#provider_struct = Ecto.build_assoc(route2, :providers,
#  %{start_time: "2021-06-18T00:51:15.1913284Z",
#    end_time: "2021-06-23T00:51:15.1913284Z",
#    price: 343375.53,
#    company: "Galaxy Express",
#    id: "b"
#  })
#provider2 = Repo.insert!(Provider.changeset(provider_struct, %{}))
#
#booking_struct = Ecto.build_assoc(provider1, :bookings, (Ecto.build_assoc(lisa, :bookings, %{status: "open", travel_time: 1})))
#booking1 = Repo.insert!(Booking.changeset(booking_struct, %{}))
#booking_struct = Ecto.build_assoc(provider2, :bookings, (Ecto.build_assoc(bart, :bookings, %{status: "closed", travel_time: 2})))
#booking2 = Repo.insert!(Booking.changeset(booking_struct, %{}))

