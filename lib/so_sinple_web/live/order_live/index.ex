defmodule SoSinpleWeb.OrderLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders
  alias SoSinple.Orders.Order
  alias SoSinple.Organizations
  alias SoSinple.Accounts
  alias SoSinple.Repo

  @impl true
  def mount(%{"group_id" => group_id, "headquarter_id" => headquarter_id}, _session, socket) do
    current_group = Organizations.get_group!(group_id) |> Repo.preload(:headquarters)
    current_headquarters = Organizations.get_headquarters!(headquarter_id)

    # Vérifier si l'utilisateur est admin du groupe ou responsable du QG
    can_manage_orders = current_group.admin_id == socket.assigns.current_user.id ||
                        Organizations.is_headquarters_manager?(socket.assigns.current_user.id, current_headquarters.id)

    {:ok,
      socket
      |> assign(:current_group, current_group)
      |> assign(:current_headquarters, current_headquarters)
      |> assign(:can_manage_orders, can_manage_orders)
      |> assign(:orders, Orders.list_headquarters_orders(headquarter_id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Modifier la commande")
    |> assign(:order, Orders.get_order!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nouvelle commande")
    |> assign(:order, %Order{headquarters_id: socket.assigns.current_headquarters.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Liste des commandes")
    |> assign(:order, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.OrderLive.FormComponent, {:saved, order}}, socket) do
    {:noreply, socket |> assign(:orders, Orders.list_headquarters_orders(socket.assigns.current_headquarters.id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    order = Orders.get_order!(id)
    {:ok, _} = Orders.delete_order(order)

    {:noreply, socket |> assign(:orders, Orders.list_headquarters_orders(socket.assigns.current_headquarters.id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @page_title %>
      <:actions>
        <.link :if={@can_manage_orders} patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/new"}>
          <.button>Nouvelle commande</.button>
        </.link>
      </:actions>
    </.header>

    <.table>
      <.table_head>
        <:col>Date création</:col>
        <:col>Date livraison</:col>
        <:col>Statut</:col>
        <:col>Client</:col>
        <:col>Téléphone</:col>
        <:col>Prix total</:col>
        <:col></:col>
      </.table_head>
      <.table_body>
        <.table_row :for={order <- @orders}>
          <:cell><%= Calendar.strftime(order.date_creation, "%d/%m/%Y %H:%M") %></:cell>
          <:cell><%= if order.date_livraison_prevue, do: Calendar.strftime(order.date_livraison_prevue, "%d/%m/%Y %H:%M"), else: "-" %></:cell>
          <:cell>
            <.badge color={order_status_color(order.status)}>
              <%= order_status_text(order.status) %>
            </.badge>
          </:cell>
          <:cell><%= order.client_nom %> <%= order.client_prenom %></:cell>
          <:cell><%= order.client_telephone %></:cell>
          <:cell><%= Number.Currency.number_to_currency(order.prix_total) %></:cell>
          <:cell>
            <div class="sr-only">
              <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{order.id}"}>
                Voir
              </.link>
            </div>
            <.dropdown>
              <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                <.icon name="hero-ellipsis-horizontal" class="size-5" />
              </:toggle>
              <.dropdown_link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{order.id}"}>
                Voir
              </.dropdown_link>
              <.dropdown_link :if={@can_manage_orders} patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{order.id}/edit"}>
                Modifier
              </.dropdown_link>
              <.dropdown_link
                :if={@can_manage_orders}
                phx-click={JS.push("delete", value: %{id: order.id}) |> hide("##{order.id}")}
                data-confirm="Êtes-vous sûr de vouloir supprimer cette commande ?"
              >
                Supprimer
              </.dropdown_link>
            </.dropdown>
          </:cell>
        </.table_row>
      </.table_body>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="order-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders")}>
      <.live_component
        module={SoSinpleWeb.OrderLive.FormComponent}
        id={@order.id || :new}
        title={@page_title}
        action={@live_action}
        order={@order}
        current_group={@current_group}
        current_headquarters={@current_headquarters}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders"}
      />
    </.modal>
    """
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
