defmodule SoSinpleWeb.OrderLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders
  alias SoSinple.Organizations

  @impl true
  def mount(%{"group_id" => group_id, "headquarter_id" => headquarter_id}, _session, socket) do


    # Vérifier si l'utilisateur est admin du groupe ou responsable du QG
    can_manage_orders = socket.assigns.current_group.admin_id == socket.assigns.current_user.id ||
                        Organizations.is_headquarters_manager?(socket.assigns.current_user.id, socket.assigns.current_headquarters.id)

    {:ok,
      socket
      |> assign(:can_manage_orders, can_manage_orders)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    order = Orders.get_order!(id) |> Orders.preload_order_items()

    {:noreply,
     socket
     |> assign(:page_title, "Modifier la commande ##{id}")
     |> assign(:order, order)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @page_title %>
      <:subtitle>
        <.badge color={order_status_color(@order.status)}>
          <%= order_status_text(@order.status) %>
        </.badge>
      </:subtitle>
    </.header>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{@order.id}"}>
      Retour aux détails de la commande
    </.back>

    <div class="mt-8">
      <.live_component
        module={SoSinpleWeb.OrderLive.FormComponent}
        id={@order.id}
        title={@page_title}
        action={:edit}
        order={@order}
        current_group={@current_group}
        current_headquarters={@current_headquarters}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{@order.id}"}
      />
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.OrderLive.FormComponent, {:saved, order}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Commande mise à jour avec succès")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.current_group.id}/headquarters/#{socket.assigns.current_headquarters.id}/orders/#{order.id}")}
  end

  defp order_status_color(status) do
    case status do
      "preparation" -> :yellow
      "pret" -> :blue
      "en_livraison" -> :purple
      "livre" -> :green
      "annule" -> :red
      _ -> :gray
    end
  end

  defp order_status_text(status) do
    case status do
      "preparation" -> "En préparation"
      "pret" -> "Prêt"
      "en_livraison" -> "En livraison"
      "livre" -> "Livré"
      "annule" -> "Annulé"
      _ -> "Inconnu"
    end
  end
end
