defmodule SoSinple.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false
  alias SoSinple.Repo

  alias SoSinple.Inventory.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  @doc """
  Returns the list of items for a specific group.
  """
  def list_items_by_group(group_id) do
    Item
    |> where([i], i.group_id == ^group_id)
    |> Repo.all()
  end

  @doc """
  Returns the list of available items for a specific group.
  """
  def list_available_items_by_group(group_id) do
    Item
    |> where([i], i.group_id == ^group_id and i.available == true)
    |> Repo.all()
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Gets a single item with preloaded group.
  """
  def get_item_with_group!(id) do
    Item
    |> Repo.get!(id)
    |> Repo.preload(:group)
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  alias SoSinple.Inventory.StockItem

  @doc """
  Returns the list of stock_items.

  ## Examples

      iex> list_stock_items()
      [%StockItem{}, ...]

  """
  def list_stock_items do
    Repo.all(StockItem)
  end

  @doc """
  Returns the list of stock_items for a specific headquarters.
  """
  def list_stock_items_by_headquarters(headquarters_id) do
    StockItem
    |> where([s], s.headquarters_id == ^headquarters_id)
    |> Repo.all()
    |> Repo.preload(:item)
  end

  @doc """
  Returns the list of stock_items for a specific item.
  """
  def list_stock_items_by_item(item_id) do
    StockItem
    |> where([s], s.item_id == ^item_id)
    |> Repo.all()
    |> Repo.preload(:headquarters)
  end

  @doc """
  Returns the list of stock_items that are below their alert threshold.
  """
  def list_stock_items_below_threshold(headquarters_id) do
    StockItem
    |> where([s], s.headquarters_id == ^headquarters_id)
    |> join(:inner, [s], i in Item, on: s.item_id == i.id)
    |> where([s, i], s.available_quantity <= s.alert_threshold and i.available == true)
    |> preload([s, i], [item: i])
    |> select([s, i], s)
    |> Repo.all()
  end

  @doc """
  Gets a single stock_item.

  Raises `Ecto.NoResultsError` if the Stock item does not exist.

  ## Examples

      iex> get_stock_item!(123)
      %StockItem{}

      iex> get_stock_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stock_item!(id), do: Repo.get!(StockItem, id)

  @doc """
  Gets a single stock_item with preloaded associations.
  """
  def get_stock_item_with_associations!(id) do
    StockItem
    |> Repo.get!(id)
    |> Repo.preload([:headquarters, :item])
  end

  @doc """
  Gets a stock_item by headquarters_id and item_id.
  Returns nil if no stock_item exists.
  """
  def get_stock_item_by_headquarters_and_item(headquarters_id, item_id) do
    StockItem
    |> where([s], s.headquarters_id == ^headquarters_id and s.item_id == ^item_id)
    |> Repo.one()
  end

  @doc """
  Creates a stock_item.

  ## Examples

      iex> create_stock_item(%{field: value})
      {:ok, %StockItem{}}

      iex> create_stock_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stock_item(attrs \\ %{}) do
    %StockItem{}
    |> StockItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stock_item.

  ## Examples

      iex> update_stock_item(stock_item, %{field: new_value})
      {:ok, %StockItem{}}

      iex> update_stock_item(stock_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stock_item(%StockItem{} = stock_item, attrs) do
    stock_item
    |> StockItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stock_item.

  ## Examples

      iex> delete_stock_item(stock_item)
      {:ok, %StockItem{}}

      iex> delete_stock_item(stock_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stock_item(%StockItem{} = stock_item) do
    Repo.delete(stock_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stock_item changes.

  ## Examples

      iex> change_stock_item(stock_item)
      %Ecto.Changeset{data: %StockItem{}}

  """
  def change_stock_item(%StockItem{} = stock_item, attrs \\ %{}) do
    StockItem.changeset(stock_item, attrs)
  end

  @doc """
  Adjusts the quantity of a stock_item.
  Positive delta increases the quantity, negative delta decreases it.
  Returns {:error, :insufficient_stock} if the delta would make the quantity negative.
  """
  def adjust_stock_quantity(%StockItem{} = stock_item, delta) when is_integer(delta) do
    if stock_item.available_quantity + delta < 0 do
      {:error, :insufficient_stock}
    else
      update_stock_item(stock_item, %{available_quantity: stock_item.available_quantity + delta})
    end
  end

  @doc """
  Checks if there is sufficient stock for an item in a headquarters.
  """
  def sufficient_stock?(headquarters_id, item_id, quantity) do
    case get_stock_item_by_headquarters_and_item(headquarters_id, item_id) do
      nil -> false
      stock_item -> stock_item.available_quantity >= quantity
    end
  end
end
