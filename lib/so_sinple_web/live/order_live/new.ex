defmodule SoSinpleWeb.OrderLive.New do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders
  alias SoSinple.Orders.Order
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
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Nouvelle commande")
     |> assign(:order, %Order{
        headquarters_id: socket.assigns.current_headquarters.id,
        date_creation: DateTime.utc_now(),
        status: "preparation"
      })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Nouvelle commande
      <:subtitle>Créer une nouvelle commande pour <%= @current_headquarters.name %></:subtitle>
    </.header>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders"}>
      Retour aux commandes
    </.back>

    <div class="mt-8">
      <.live_component
        module={SoSinpleWeb.OrderLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
        order={@order}
        current_group={@current_group}
        current_headquarters={@current_headquarters}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders"}
      />
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.OrderLive.FormComponent, {:saved, _order}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Commande créée avec succès")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.current_group.id}/headquarters/#{socket.assigns.current_headquarters.id}/orders")}
  end
end
