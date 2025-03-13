defmodule SoSinple.Organizations.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ["admin_groupe", "responsable_qg", "livreur"]

  schema "user_roles" do
    field :active, :boolean, default: true
    field :role, :string

    belongs_to :user, SoSinple.Accounts.User
    belongs_to :group, SoSinple.Organizations.Group
    belongs_to :headquarters, SoSinple.Organizations.Headquarters

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:active, :role, :user_id, :group_id, :headquarters_id])
    |> validate_required([:active, :role, :user_id, :group_id])
    |> validate_inclusion(:role, @roles)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:group_id)
    |> foreign_key_constraint(:headquarters_id)
    |> validate_headquarters_if_needed()
  end

  # Valide que headquarters_id est présent si le rôle est responsable_qg ou livreur
  defp validate_headquarters_if_needed(changeset) do
    role = get_field(changeset, :role)

    if role in ["responsable_qg", "livreur"] do
      validate_required(changeset, [:headquarters_id])
    else
      changeset
    end
  end

  # Fonction utilitaire pour obtenir la liste des rôles disponibles
  def roles, do: @roles
end
