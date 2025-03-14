defmodule SoSinple.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string
      add :description, :text
      add :price, :float
      add :image_url, :string
      add :available, :boolean, default: false, null: false
      add :group_id, references(:groups, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:group_id])
  end
end
