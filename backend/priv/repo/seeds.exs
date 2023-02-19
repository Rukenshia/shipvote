# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Backend.Repo.insert!(%Backend.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, date} = NaiveDateTime.new(2019, 1, 1, 0, 0, 0)

channel =
  Backend.Repo.insert!(%Backend.Stream.Channel{
    inserted_at: date,
    wows_username: "AlongUsernameForTests"
  })

ships = [
  Backend.Repo.insert!(%Backend.Wows.Warship{
    id: 4_282_267_344,
    name: "Shimakaze",
    type: "Destroyer",
    nation: "japan",
    premium: false,
    image:
      "https://glossary-wows-global.gcdn.co/icons//vehicle/small/PJSD012_abe195480c5687e0a492b11dcd83d8117b278c8c3aa8bc794b3df3ed77c21c26.png",
    tier: 10
  }),
  Backend.Repo.insert!(%Backend.Wows.Warship{
    id: 4_273_911_792,
    name: "Des Moines",
    type: "Cruiser",
    nation: "usa",
    premium: false,
    image:
      "https://glossary-wows-global.gcdn.co/icons//vehicle/small/PASC020_6d8433ad54145db2092483c2e1a72af6be632ac638654dff0541c8f54f4106a7.png",
    tier: 10
  }),
  Backend.Repo.insert!(%Backend.Wows.Warship{
    id: 3_741_234_640,
    name: "Ochakov",
    type: "Cruiser",
    nation: "ussr",
    premium: true,
    image:
      "https://glossary-wows-global.gcdn.co/icons//vehicle/small/PRSC528_3af1645d2772ab315efe19affa1cf879685d8b470577a56d1f726fd233dd213f.png",
    tier: 8
  }),
  Backend.Repo.insert!(%Backend.Wows.Warship{
    id: 4_281_219_056,
    name: "Gearing",
    type: "Destroyer",
    nation: "usa",
    premium: false,
    image:
      "https://glossary-wows-global.gcdn.co/icons//vehicle/small/PASD013_cf35f9528df69fef9880f2d65cf467010068268307c5f679cc2f2b2b93bc26d5.png",
    tier: 10
  })
]

for ship <- ships do
  {:ok, _} =
    Backend.Stream.create_channel_ship(%{
      channel_id: channel.id,
      ship_id: ship.id,
      enabled: true
    })
end

active_vote =
  Backend.Repo.insert!(%Backend.Stream.Vote{
    channel_id: channel.id,
    ships: [4_281_219_056, 3_741_234_640, 4_273_911_792, 2_282_267_344],
    status: "open"
  })

for i <- 0..29 do
  Backend.Repo.insert!(%Backend.Stream.VotedShip{
    vote: active_vote,
    user_id: "#{i}",
    ship_id: 4_282_267_344
  })
end

for i <- 30..54 do
  Backend.Repo.insert!(%Backend.Stream.VotedShip{
    vote: active_vote,
    user_id: "#{i}",
    ship_id: 3_741_234_640
  })
end

for i <- 55..74 do
  Backend.Repo.insert!(%Backend.Stream.VotedShip{
    vote: active_vote,
    user_id: "#{i}",
    ship_id: 4_273_911_792
  })
end

for i <- 75..89 do
  Backend.Repo.insert!(%Backend.Stream.VotedShip{
    vote: active_vote,
    user_id: "#{i}",
    ship_id: 4_281_219_056
  })
end

# Closed Votes for example channel
closed_votes = [
  Backend.Repo.insert!(%Backend.Stream.Vote{
    channel_id: channel.id,
    ships: [4_281_219_056, 3_741_234_640, 4_273_911_792],
    status: "closed"
  }),
  Backend.Repo.insert!(%Backend.Stream.Vote{
    channel_id: channel.id,
    ships: [4_281_219_056, 3_741_234_640, 4_273_911_792],
    status: "closed"
  })
]

for vote <- closed_votes do
  for i <- 0..4 do
    Backend.Repo.insert!(%Backend.Stream.VotedShip{
      vote: vote,
      user_id: "#{i}",
      ship_id: 4_281_219_056
    })
  end

  for i <- 5..8 do
    Backend.Repo.insert!(%Backend.Stream.VotedShip{
      vote: vote,
      user_id: "#{i}",
      ship_id: 3_741_234_640
    })
  end
end

Backend.Repo.insert!(%Backend.Stream.VotedShip{
  vote: closed_votes |> Enum.at(0),
  user_id: "last_vote",
  ship_id: 4_273_911_792
})

# More channels
Backend.Repo.insert!(%Backend.Stream.Channel{})
Backend.Repo.insert!(%Backend.Stream.Channel{})
Backend.Repo.insert!(%Backend.Stream.Channel{})
Backend.Repo.insert!(%Backend.Stream.Channel{})

inactive_channel =
  Backend.Repo.insert!(%Backend.Stream.Channel{
    id: 4711,
    wows_username: "inactive_user"
  })

v =
  Backend.Repo.insert!(%Backend.Stream.Vote{
    channel_id: inactive_channel.id,
    ships: [],
    status: "closed"
  })

v
|> Backend.Stream.Vote.changeset(%{
  inserted_at:
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.add(-60 * 60 * 24 * 365, :second)
})
|> Backend.Repo.update!()
