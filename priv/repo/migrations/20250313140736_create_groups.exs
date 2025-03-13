defmodule SoSinple.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string
      add :description, :string
      add :active, :boolean, default: false, null: false
      add :admin_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:groups, [:admin_id])
  end
end
