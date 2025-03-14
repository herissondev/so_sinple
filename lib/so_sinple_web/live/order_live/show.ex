defmodule SoSinpleWeb.OrderLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders
  alias SoSinple.Organizations
  alias SoSinple.Accounts

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
  def handle_params(%{"id" => id}, _, socket) do
    order = Orders.get_order!(id) |> Orders.preload_order_items()

    {:noreply,
     socket
     |> assign(:page_title, "Commande ##{id}")
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
      <:actions>
        <.link :if={@can_manage_orders} patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{@order.id}/edit"} phx-click={JS.push_focus()}>
          <.button>Modifier</.button>
        </.link>
      </:actions>
    </.header>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders"}>
      Retour aux commandes
    </.back>

    <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-8">
      <div>
        <div class="bg-white shadow rounded-lg p-6">
          <div class="border-b pb-4 mb-4">
            <h3 class="text-lg font-semibold">Informations client</h3>
          </div>
          <.list>
            <:item title="Nom"><%= @order.client_nom %> <%= @order.client_prenom %></:item>
            <:item title="Téléphone"><%= @order.client_telephone %></:item>
            <:item title="Adresse"><%= @order.client_adresse %></:item>
          </.list>
        </div>
      </div>

      <div>
        <div class="bg-white shadow rounded-lg p-6">
          <div class="border-b pb-4 mb-4">
            <h3 class="text-lg font-semibold">Informations livraison</h3>
          </div>
          <.list>
            <:item title="Adresse de livraison"><%= @order.adresse_livraison %></:item>
            <:item title="Date de création"><%= Calendar.strftime(@order.date_creation, "%d/%m/%Y %H:%M") %></:item>
            <:item title="Date de livraison prévue">
              <%= if @order.date_livraison_prevue, do: Calendar.strftime(@order.date_livraison_prevue, "%d/%m/%Y %H:%M"), else: "-" %>
            </:item>
            <:item title="Livreur">
              <%= if @order.livreur_id do %>
                <%= Accounts.get_user!(@order.livreur_id).email %>
              <% else %>
                Non assigné
              <% end %>
            </:item>
          </.list>
        </div>
      </div>
    </div>

    <div class="bg-white shadow rounded-lg p-6 mt-8">
      <div class="border-b pb-4 mb-4">
        <h3 class="text-lg font-semibold">Articles commandés</h3>
      </div>
      <.table>
        <.table_head>
          <:col>Article</:col>
          <:col>Quantité</:col>
          <:col>Prix unitaire</:col>
          <:col>Total</:col>
          <:col>Notes</:col>
        </.table_head>
        <.table_body>
          <.table_row :for={item <- @order.order_items}>
            <:cell><%= item.item.name %></:cell>
            <:cell><%= item.quantite %></:cell>
            <:cell><%= Number.Currency.number_to_currency(item.prix_unitaire) %></:cell>
            <:cell><%= Number.Currency.number_to_currency(item.prix_unitaire * item.quantite) %></:cell>
            <:cell><%= item.notes_speciales || "-" %></:cell>
          </.table_row>
        </.table_body>
      </.table>
      <div class="mt-4 text-right font-bold text-lg">
        Total: <%= Number.Currency.number_to_currency(@order.prix_total) %>
      </div>
    </div>

    <div :if={@order.notes} class="bg-white shadow rounded-lg p-6 mt-8">
      <div class="border-b pb-4 mb-4">
        <h3 class="text-lg font-semibold">Notes</h3>
      </div>
      <p><%= @order.notes %></p>
    </div>

    <.modal :if={@live_action == :edit} id="order-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{@order.id}")}>
      <.live_component
        module={SoSinpleWeb.OrderLive.FormComponent}
        id={@order.id}
        title={@page_title}
        action={@live_action}
        order={@order}
        current_group={@current_group}
        current_headquarters={@current_headquarters}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/orders/#{@order.id}"}
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
