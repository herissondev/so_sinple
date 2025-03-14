defmodule SoSinple.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items) do
      add :quantite, :integer
      add :prix_unitaire, :float
      add :notes_speciales, :string
      add :commande_id, references(:orders, on_delete: :nothing)
      add :item_id, references(:items, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:order_items, [:commande_id])
    create index(:order_items, [:item_id])
  end
end
