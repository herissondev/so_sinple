defmodule SoSinpleWeb.DeliveryLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders
  alias SoSinple.Orders.Order
  alias SoSinple.Organizations

  @impl true
  def mount(_params, _session, socket) do
    livreur_id = socket.assigns.current_user.id
    delivery_headquarters_ids = socket.assigns.delivery_headquarters_ids
    assigned_orders = Orders.list_orders_by_delivery_person(livreur_id)

    # Les commandes prêtes pour attribution (statut "pret" sans livreur assigné)
    available_orders = Enum.flat_map(delivery_headquarters_ids, fn hq_id ->
      Orders.list_orders_ready_for_assignment(hq_id)
    end)

    {:ok, socket
    |> assign(:assigned_orders, assigned_orders)
    |> assign(:available_orders, available_orders)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Commandes à livrer")
  end

  @impl true
  def handle_event("start_delivery", %{"id" => id}, socket) do
    order = Orders.get_order!(id)

    # Vérifier que le livreur est bien assigné à cette commande
    if order.livreur_id == socket.assigns.current_user.id do
      case Orders.start_delivery(order) do
        {:ok, _updated_order} ->
          {:noreply, socket
           |> put_flash(:info, "Statut de la commande mis à jour.")
           |> push_redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/delivery/orders/#{order.id}")}

        {:error, changeset} ->
          {:noreply, socket
           |> put_flash(:error, "Erreur lors de la mise à jour de la commande: #{inspect(changeset.errors)}")}
      end
    else
      {:noreply, socket
      |> put_flash(:error, "Vous n'êtes pas autorisé à modifier cette commande.")}
    end
  end

  @impl true
  def handle_event("self_assign", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Orders.self_assign_delivery_person(id, user_id) do
      {:ok, _updated_order} ->
        {:noreply, socket
         |> put_flash(:info, "Commande assignée avec succès.")
         |> push_redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/delivery")}

      {:error, reason} ->
        error_msg = case reason do
          :order_not_found -> "Commande introuvable."
          :invalid_order_status -> "La commande n'est pas dans un état permettant l'assignation."
          _ -> "Erreur lors de l'assignation de la commande: #{inspect(reason)}"
        end

        {:noreply, socket
         |> put_flash(:error, error_msg)}
    end
  end
end
