defmodule SoSinple.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias SoSinple.Repo

  alias SoSinple.Orders.Order

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  alias SoSinple.Orders.OrderItem

  @doc """
  Returns the list of order_items.

  ## Examples

      iex> list_order_items()
      [%OrderItem{}, ...]

  """
  def list_order_items do
    Repo.all(OrderItem)
  end

  @doc """
  Gets a single order_item.

  Raises `Ecto.NoResultsError` if the Order item does not exist.

  ## Examples

      iex> get_order_item!(123)
      %OrderItem{}

      iex> get_order_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order_item!(id), do: Repo.get!(OrderItem, id)

  @doc """
  Creates a order_item.

  ## Examples

      iex> create_order_item(%{field: value})
      {:ok, %OrderItem{}}

      iex> create_order_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order_item(attrs \\ %{}) do
    %OrderItem{}
    |> OrderItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a order_item.

  ## Examples

      iex> update_order_item(order_item, %{field: new_value})
      {:ok, %OrderItem{}}

      iex> update_order_item(order_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order_item(%OrderItem{} = order_item, attrs) do
    order_item
    |> OrderItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order_item.

  ## Examples

      iex> delete_order_item(order_item)
      {:ok, %OrderItem{}}

      iex> delete_order_item(order_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order_item(%OrderItem{} = order_item) do
    Repo.delete(order_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order_item changes.

  ## Examples

      iex> change_order_item(order_item)
      %Ecto.Changeset{data: %OrderItem{}}

  """
  def change_order_item(%OrderItem{} = order_item, attrs \\ %{}) do
    OrderItem.changeset(order_item, attrs)
  end

  @doc """
  Returns the list of orders for a specific headquarters.

  ## Examples

      iex> list_headquarters_orders(1)
      [%Order{}, ...]

  """
  def list_headquarters_orders(headquarters_id) do
    Order
    |> where([o], o.headquarters_id == ^headquarters_id)
    |> order_by([o], desc: o.date_creation)
    |> Repo.all()
  end

  @doc """
  Preloads order items for an order.

  ## Examples

      iex> preload_order_items(order)
      %Order{order_items: [%OrderItem{}, ...]}

  """
  def preload_order_items(%Order{} = order) do
    order = Repo.preload(order, [order_items: [item: []]])
    order
  end

  @doc """
  Returns the list of order items for a specific order.

  ## Examples

      iex> list_order_items_by_order(1)
      [%OrderItem{}, ...]

  """
  def list_order_items_by_order(order_id) do
    OrderItem
    |> where([oi], oi.commande_id == ^order_id)
    |> Repo.all()
    |> Repo.preload(:item)
  end

  @doc """
  Creates an order with its items in a transaction.

  ## Examples

      iex> create_order_with_items(%{field: value}, [%{field: value}, ...])
      {:ok, %{order: %Order{}, items: [%OrderItem{}, ...]}}

      iex> create_order_with_items(%{field: bad_value}, [])
      {:error, :order, %Ecto.Changeset{}, %{}}

  """
  def create_order_with_items(order_attrs, items_attrs) do
    Repo.transaction(fn ->
      with {:ok, order} <- create_order(order_attrs),
           {:ok, items} <- create_order_items(order.id, items_attrs) do
        %{order: order, items: items}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp create_order_items(order_id, items_attrs) do
    items_result =
      Enum.map(items_attrs, fn attrs ->
        create_order_item(Map.put(attrs, "commande_id", order_id))
      end)

    if Enum.all?(items_result, fn {status, _} -> status == :ok end) do
      {:ok, Enum.map(items_result, fn {:ok, item} -> item end)}
    else
      {:error, Enum.find(items_result, fn {status, _} -> status == :error end) |> elem(1)}
    end
  end

  @doc """
  Updates an order status.

  ## Examples

      iex> update_order_status(order, "en_livraison")
      {:ok, %Order{}}

      iex> update_order_status(order, "invalid_status")
      {:error, %Ecto.Changeset{}}

  """
  def update_order_status(%Order{} = order, status) do
    update_order(order, %{status: status})
  end

  @doc """
  Assigns a delivery person to an order.

  ## Examples

      iex> assign_delivery_person(order, 1)
      {:ok, %Order{}}

  """
  def assign_delivery_person(%Order{} = order, user_id) do
    update_order(order, %{livreur_id: user_id})
  end
end
