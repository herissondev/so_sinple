defmodule SoSinple.Repo do
  use Ecto.Repo,
    otp_app: :so_sinple,
    adapter: Ecto.Adapters.SQLite3
end
