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

chan =
  Backend.Repo.insert!(%Backend.Stream.Channel{
    inserted_at: date,
    wows_username: "AlongUsernameForTests"
  })

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

for i <- 0..100 do
  Backend.Repo.insert!(%Backend.Stream.Vote{
    channel_id: chan.id,
    ships: [],
    status: if(rem(i, 2) == 0, do: "closed", else: "open"),
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  })
end
