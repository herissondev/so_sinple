defmodule SoSinple.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :status, :date_creation, :date_livraison_prevue, :client_nom, :client_prenom, :client_adresse, :client_telephone, :prix_total, :adresse_livraison, :latitude_livraison, :longitude_livraison, :notes, :headquarters_id, :livreur_id]}
  schema "orders" do
    field :status, :string
    field :date_creation, :naive_datetime
    field :date_livraison_prevue, :naive_datetime
    field :client_nom, :string
    field :client_prenom, :string
    field :client_adresse, :string
    field :client_telephone, :string
    field :prix_total, :float
    field :adresse_livraison, :string
    field :latitude_livraison, :float
    field :longitude_livraison, :float
    field :notes, :string

    belongs_to :headquarters, SoSinple.Organizations.Headquarters
    belongs_to :livreur, SoSinple.Accounts.User, foreign_key: :livreur_id

    has_many :order_items, SoSinple.Orders.OrderItem, foreign_key: :commande_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:date_creation, :date_livraison_prevue, :status, :client_nom, :client_prenom, :client_adresse, :client_telephone, :prix_total, :adresse_livraison, :latitude_livraison, :longitude_livraison, :notes, :headquarters_id, :livreur_id])
    |> validate_required([:date_creation, :status, :client_nom, :client_prenom, :client_telephone, :adresse_livraison, :headquarters_id])
    |> validate_inclusion(:status, ["preparation", "pret", "en_livraison", "livre", "annule"])
    |> validate_number(:prix_total, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:headquarters_id)
    |> foreign_key_constraint(:livreur_id)
  end
end
