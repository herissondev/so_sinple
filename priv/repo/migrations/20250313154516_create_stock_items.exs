defmodule SoSinple.Repo.Migrations.CreateStockItems do
  use Ecto.Migration

  def change do
    create table(:stock_items) do
      add :available_quantity, :integer
      add :alert_threshold, :integer
      add :headquarters_id, references(:headquarters, on_delete: :nothing)
      add :item_id, references(:items, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:stock_items, [:headquarters_id])
    create index(:stock_items, [:item_id])
    create unique_index(:stock_items, [:headquarters_id, :item_id], name: "stock_items_headquarters_id_item_id_index")
  end
end
