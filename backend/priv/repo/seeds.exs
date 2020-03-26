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

chan = Backend.Repo.insert!(%Backend.Stream.Channel{
  inserted_at: date,
  wows_username: "foo"
})
Backend.Repo.insert!(%Backend.Stream.Channel{})
Backend.Repo.insert!(%Backend.Stream.Channel{})
Backend.Repo.insert!(%Backend.Stream.Channel{})
Backend.Repo.insert!(%Backend.Stream.Channel{})

Backend.Repo.insert!(%Backend.Stream.Vote{
  channel_id: chan.id,
  ships: [],
})
