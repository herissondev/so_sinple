defmodule SoSinple.Repo.Migrations.CreateHeadquarters do
  use Ecto.Migration

  def change do
    create table(:headquarters) do
      add :name, :string
      add :address, :string
      add :latitude, :float
      add :longitude, :float
      add :phone, :string
      add :active, :boolean, default: false, null: false
      add :group_id, references(:groups, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:headquarters, [:group_id])
  end
end
