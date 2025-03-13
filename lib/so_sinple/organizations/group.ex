defmodule SoSinple.Organizations.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :active, :boolean, default: true
    field :name, :string
    field :description, :string

    belongs_to :admin, SoSinple.Accounts.User, foreign_key: :admin_id
    has_many :headquarters, SoSinple.Organizations.Headquarters
    has_many :user_roles, SoSinple.Organizations.UserRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description, :active, :admin_id])
    |> validate_required([:name, :description, :active])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:description, max: 500)
    |> foreign_key_constraint(:admin_id)
  end
end
