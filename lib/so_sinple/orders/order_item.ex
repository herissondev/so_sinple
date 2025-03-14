defmodule SoSinple.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_items" do
    field :quantite, :integer
    field :prix_unitaire, :float
    field :notes_speciales, :string

    belongs_to :commande, SoSinple.Orders.Order, foreign_key: :commande_id
    belongs_to :item, SoSinple.Inventory.Item

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantite, :prix_unitaire, :notes_speciales, :commande_id, :item_id])
    |> validate_required([:quantite, :prix_unitaire, :commande_id, :item_id])
    |> validate_number(:quantite, greater_than: 0)
    |> validate_number(:prix_unitaire, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:commande_id)
    |> foreign_key_constraint(:item_id)
  end
end
