defmodule SoSinple.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SoSinple.Inventory` context.
  """

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        available: true,
        description: "some description",
        image_url: "some image_url",
        name: "some name",
        price: 120.5
      })
      |> SoSinple.Inventory.create_item()

    item
  end

  @doc """
  Generate a stock_item.
  """
  def stock_item_fixture(attrs \\ %{}) do
    {:ok, stock_item} =
      attrs
      |> Enum.into(%{
        alert_threshold: 42,
        available_quantity: 42
      })
      |> SoSinple.Inventory.create_stock_item()

    stock_item
  end
end
