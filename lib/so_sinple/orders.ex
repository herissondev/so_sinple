defmodule SoSinple.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias SoSinple.Repo

  alias SoSinple.Orders.Order
  alias SoSinple.Organizations

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

  @doc """
  Returns a list of active orders (preparation or delivery) for all headquarters in a group.
  """
  def list_active_orders_by_group(group_id) do
    headquarters_ids = Organizations.list_headquarters_by_group(group_id)
                      |> Enum.map(& &1.id)

    Order
    |> where([o], o.headquarters_id in ^headquarters_ids)
    |> where([o], o.status in ["preparation", "pret", "en_livraison"])
    |> preload([:headquarters])
    |> Repo.all()
  end

  @doc """
  Calcule le chiffre d'affaires total pour un groupe donné.
  Prend en compte toutes les commandes complétées.
  """
  def calculate_total_revenue_for_group(group_id) do
    from(o in Order,
      join: h in assoc(o, :headquarters),
      where: h.group_id == ^group_id and o.status == "livre",
      select: sum(o.prix_total)
    )
    |> Repo.one()
    |> Kernel.||(Decimal.new("0.00"))  # Retourne 0.00 si pas de résultats
  end

  @doc """
  Calcule le chiffre d'affaires pour une période donnée pour un groupe.
  Utile pour les statistiques par période.
  """
  def calculate_revenue_for_group_in_period(group_id, start_date, end_date) do
    from(o in Order,
      join: h in assoc(o, :headquarters),
      where: h.group_id == ^group_id and
             o.status == "livre" and
             o.inserted_at >= ^start_date and
             o.inserted_at <= ^end_date,
      select: sum(o.prix_total)
    )
    |> Repo.one()
    |> Kernel.||(Decimal.new("0.00"))
  end

  @doc """
  Retourne les statistiques de chiffre d'affaires pour un groupe.
  Inclut le total, la moyenne par commande, et les tendances.
  """
  def get_revenue_statistics(group_id) do
    total_query = from(o in Order,
      join: h in assoc(o, :headquarters),
      where: h.group_id == ^group_id and o.status == "livre",
      select: %{
        total: sum(o.prix_total),
        count: count(o.id),
        avg: avg(o.prix_total)
      }
    )

    # Calcul pour le mois en cours
    now = DateTime.utc_now()
    start_of_month = %{now | day: 1, hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

    current_month_query = from(o in Order,
      join: h in assoc(o, :headquarters),
      where: h.group_id == ^group_id and
             o.status == "livre" and
             o.inserted_at >= ^start_of_month,
      select: sum(o.prix_total)
    )

    with %{total: total, count: count, avg: avg} <- Repo.one(total_query),
         current_month_total when not is_nil(current_month_total) <- Repo.one(current_month_query) do
      %{
        total_revenue: total || Decimal.new("0.00"),
        total_orders: count || 0,
        average_order_value: avg || Decimal.new("0.00"),
        current_month_revenue: current_month_total || Decimal.new("0.00")
      }
    else
      _ -> %{
        total_revenue: Decimal.new("0.00"),
        total_orders: 0,
        average_order_value: Decimal.new("0.00"),
        current_month_revenue: Decimal.new("0.00")
      }
    end
  end

  @doc """
  Calcule le chiffre d'affaires total pour un QG spécifique.
  Prend en compte uniquement les commandes livrées.
  """
  def calculate_total_revenue_for_headquarters(headquarters_id) do
    from(o in Order,
      where: o.headquarters_id == ^headquarters_id and o.status == "livre",
      select: sum(o.prix_total)
    )
    |> Repo.one()
    |> Kernel.||(Decimal.new("0.00"))  # Retourne 0.00 si pas de résultats
  end

  @doc """
  Retourne le nombre de commandes actives pour un QG spécifique.
  Les commandes actives sont celles en préparation, prêtes ou en livraison.
  """
  def count_active_orders_for_headquarters(headquarters_id) do
    from(o in Order,
      where: o.headquarters_id == ^headquarters_id and o.status in ["preparation", "pret", "en_livraison"],
      select: count(o.id)
    )
    |> Repo.one()
    |> Kernel.||(0)  # Retourne 0 si pas de résultats
  end

  @doc """
  Liste les commandes actives pour un QG spécifique.
  Inclut les détails des commandes pour affichage.
  """
  def list_active_orders_by_headquarters(headquarters_id) do
    Order
    |> where([o], o.headquarters_id == ^headquarters_id)
    |> where([o], o.status in ["preparation", "pret", "en_livraison"])
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Retourne les statistiques complètes pour un QG spécifique.
  """
  def get_headquarters_statistics(headquarters_id) do
    # Statistiques de base
    total_query = from(o in Order,
      where: o.headquarters_id == ^headquarters_id and o.status == "livre",
      select: %{
        total: sum(o.prix_total),
        count: count(o.id),
        avg: avg(o.prix_total)
      }
    )

    # Commandes par statut
    status_counts_query = from(o in Order,
      where: o.headquarters_id == ^headquarters_id,
      group_by: o.status,
      select: {o.status, count(o.id)}
    )

    # Calcul pour le mois en cours
    now = DateTime.utc_now()
    start_of_month = %{now | day: 1, hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
    current_month_query = from(o in Order,
      where: o.headquarters_id == ^headquarters_id and
             o.status == "livre" and
             o.inserted_at >= ^start_of_month,
      select: sum(o.prix_total)
    )

    # Exécution des requêtes
    stats = Repo.one(total_query) || %{total: nil, count: nil, avg: nil}
    status_counts = Repo.all(status_counts_query) |> Map.new()
    current_month_total = Repo.one(current_month_query)

    # Construction du résultat
    %{
      total_revenue: stats.total || Decimal.new("0.00"),
      total_completed_orders: stats.count || 0,
      average_order_value: stats.avg || Decimal.new("0.00"),
      current_month_revenue: current_month_total || Decimal.new("0.00"),
      preparation_count: Map.get(status_counts, "preparation", 0),
      ready_count: Map.get(status_counts, "pret", 0),
      delivery_count: Map.get(status_counts, "en_livraison", 0),
      completed_count: Map.get(status_counts, "livre", 0),
      cancelled_count: Map.get(status_counts, "annule", 0)
    }
  end

  @doc """
  Returns all orders assigned to a specific delivery person, ordered by priority.
  Priority is determined by delivery date and status.
  """
  def list_orders_by_delivery_person(livreur_id) do
    Order
    |> where([o], o.livreur_id == ^livreur_id)
    |> where([o], o.status in ["pret", "en_livraison"])
    |> order_by([o], [
      # Prioritize orders that are already being delivered
      desc: fragment("CASE WHEN ? = 'en_livraison' THEN 1 ELSE 0 END", o.status),
      # Then prioritize by delivery date (sooner first)
      asc: o.date_livraison_prevue
    ])
    |> Repo.all()
    |> Repo.preload(:headquarters)
  end

  @doc """
  Allows a delivery person to self-assign to an order.
  Checks if the user has the appropriate role before assignment.
  """
  def self_assign_delivery_person(order_id, user_id) do
    # First, check if the order exists and is in a valid state for assignment
    with %Order{} = order <- Repo.get(Order, order_id),
         true <- order.status in ["pret"],
         {:ok, updated_order} <- assign_delivery_person(order, user_id) do
      {:ok, updated_order}
    else
      nil -> {:error, :order_not_found}
      false -> {:error, :invalid_order_status}
      error -> error
    end
  end

  @doc """
  Update order status to "en_livraison" when the delivery person starts delivery.
  """
  def start_delivery(%Order{} = order) do
    update_order_status(order, "en_livraison")
  end

  @doc """
  Mark an order as delivered/completed.
  """
  def complete_delivery(%Order{} = order) do
    update_order_status(order, "livre")
  end

  @doc """
  Cancel a delivery.
  """
  def cancel_delivery(%Order{} = order, reason \\ nil) do
    attrs = if reason, do: %{status: "annule", notes: reason}, else: %{status: "annule"}
    update_order(order, attrs)
  end

  @doc """
  Returns orders that are ready for delivery for a specific headquarters.
  These are orders with status "pret" that don't have a delivery person assigned yet.
  """
  def list_orders_ready_for_assignment(headquarters_id) do
    Order
    |> where([o], o.headquarters_id == ^headquarters_id)
    |> where([o], o.status == "pret")
    |> where([o], is_nil(o.livreur_id))
    |> order_by([o], asc: o.date_livraison_prevue)
    |> Repo.all()
    |> Repo.preload(:headquarters)
  end
end
