# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     API.Repo.insert!(%API.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# ------ Superuser

skj =
  API.Repo.insert!(%API.User{
    role: :superuser,
    display_name: "KJ Sam",
    email_address: "samkj.ks@gmail.com",
    gender: :male
  })

API.Repo.insert!(%API.HandleName{
  user_id: skj.id,
  value: "sammkj"
})

tht =
  API.Repo.insert!(%API.User{
    role: :superuser,
    display_name: "Dr. Tan",
    email_address: "huitingtan93@gmail.com",
    gender: :female
  })

API.Repo.insert!(%API.HandleName{
  user_id: tht.id,
  value: "ariesting"
})
