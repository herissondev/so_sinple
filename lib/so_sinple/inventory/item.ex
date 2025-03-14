defmodule SoSinple.Inventory.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    field :description, :string
    field :available, :boolean, default: true
    field :price, :float
    field :image_url, :string

    belongs_to :group, SoSinple.Organizations.Group
    has_many :stock_items, SoSinple.Inventory.StockItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :description, :price, :image_url, :available, :group_id])
    |> validate_required([:name, :description, :price, :group_id])
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:group_id)
  end
end
