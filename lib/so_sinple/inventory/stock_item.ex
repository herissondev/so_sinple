defmodule SoSinple.Inventory.StockItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_items" do
    field :available_quantity, :integer, default: 0
    field :alert_threshold, :integer, default: 10

    belongs_to :headquarters, SoSinple.Organizations.Headquarters
    belongs_to :item, SoSinple.Inventory.Item

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(stock_item, attrs) do
    stock_item
    |> cast(attrs, [:available_quantity, :alert_threshold, :headquarters_id, :item_id])
    |> validate_required([:available_quantity, :alert_threshold, :headquarters_id, :item_id])
    |> validate_number(:available_quantity, greater_than_or_equal_to: 0)
    |> validate_number(:alert_threshold, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:headquarters_id)
    |> foreign_key_constraint(:item_id)
    |> unique_constraint([:headquarters_id, :item_id], name: "stock_items_headquarters_id_item_id_index", message: "Stock item already exists for this headquarters and item")
  end

  @doc """
  Vérifie si le stock est en dessous du seuil d'alerte.
  """
  def below_alert_threshold?(%__MODULE__{} = stock_item) do
    stock_item.available_quantity <= stock_item.alert_threshold
  end
end
