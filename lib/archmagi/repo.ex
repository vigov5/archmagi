defmodule Archmagi.Repo do
  use Ecto.Repo,
    otp_app: :archmagi,
    adapter: Ecto.Adapters.Postgres
end
