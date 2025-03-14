defmodule SoSinple.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :date_creation, :naive_datetime
      add :date_livraison_prevue, :naive_datetime
      add :status, :string
      add :client_nom, :string
      add :client_prenom, :string
      add :client_adresse, :string
      add :client_telephone, :string
      add :prix_total, :float
      add :adresse_livraison, :string
      add :latitude_livraison, :float
      add :longitude_livraison, :float
      add :notes, :string
      add :headquarters_id, references(:headquarters, on_delete: :nothing)
      add :livreur_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:headquarters_id])
    create index(:orders, [:livreur_id])
  end
end
