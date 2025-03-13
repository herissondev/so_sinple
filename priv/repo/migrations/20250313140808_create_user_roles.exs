defmodule SoSinple.Repo.Migrations.CreateUserRoles do
  use Ecto.Migration

  def change do
    create table(:user_roles) do
      add :active, :boolean, default: false, null: false
      add :role, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :group_id, references(:groups, on_delete: :nothing)
      add :headquarters_id, references(:headquarters, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_roles, [:user_id])
    create index(:user_roles, [:group_id])
    create index(:user_roles, [:headquarters_id])
  end
end
