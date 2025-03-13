defmodule SoSinple.Organizations.Headquarters do
  use Ecto.Schema
  import Ecto.Changeset

  schema "headquarters" do
    field :active, :boolean, default: true
    field :name, :string
    field :address, :string
    field :latitude, :float
    field :longitude, :float
    field :phone, :string

    belongs_to :group, SoSinple.Organizations.Group
    has_many :user_roles, SoSinple.Organizations.UserRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(headquarters, attrs) do
    headquarters
    |> cast(attrs, [:name, :address, :latitude, :longitude, :phone, :active, :group_id])
    |> validate_required([:name, :address, :latitude, :longitude, :phone, :active, :group_id])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:address, min: 5, max: 255)
    |> validate_length(:phone, min: 8, max: 20)
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> foreign_key_constraint(:group_id)
  end
end
