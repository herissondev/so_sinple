defmodule SoSinple.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SoSinple.Orders` context.
  """

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        adresse_livraison: "some adresse_livraison",
        client_adresse: "some client_adresse",
        client_nom: "some client_nom",
        client_prenom: "some client_prenom",
        client_telephone: "some client_telephone",
        date_creation: ~U[2025-03-12 21:58:00Z],
        date_livraison_prevue: ~U[2025-03-12 21:58:00Z],
        latitude_livraison: 120.5,
        longitude_livraison: 120.5,
        notes: "some notes",
        prix_total: 120.5,
        status: "some status"
      })
      |> SoSinple.Orders.create_order()

    order
  end

  @doc """
  Generate a order_item.
  """
  def order_item_fixture(attrs \\ %{}) do
    {:ok, order_item} =
      attrs
      |> Enum.into(%{
        notes_speciales: "some notes_speciales",
        prix_unitaire: 120.5,
        quantite: 42
      })
      |> SoSinple.Orders.create_order_item()

    order_item
  end

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        adresse_livraison: "some adresse_livraison",
        client_adresse: "some client_adresse",
        client_nom: "some client_nom",
        client_prenom: "some client_prenom",
        client_telephone: "some client_telephone",
        date_creation: ~N[2025-03-12 22:03:00],
        date_livraison_prevue: ~N[2025-03-12 22:03:00],
        latitude_livraison: 120.5,
        longitude_livraison: 120.5,
        notes: "some notes",
        prix_total: 120.5,
        status: "some status"
      })
      |> SoSinple.Orders.create_order()

    order
  end
end
