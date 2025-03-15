defmodule SoSinpleWeb.GroupLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Inventory
  alias SoSinple.Orders

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => id}, _, socket) do
    group = Organizations.get_group_with_admin!(id)
    headquarters_list = Organizations.list_headquarters_by_group(id)
    items_list = Inventory.list_items_by_group(id)

    # Get active orders for all headquarters in the group
    active_orders = Orders.list_active_orders_by_group(id)

    # Calculer le chiffre d'affaires total (à adapter selon votre logique de calcul)
    total_revenue = Orders.calculate_total_revenue_for_group(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = group.admin_id == socket.assigns.current_user.id

    {:noreply,
     socket
     |> assign(:page_title, "Group: #{group.name}")
     |> assign(:group, group)
     |> assign(:headquarters_list, headquarters_list)
     |> assign(:items_list, items_list)
     |> assign(:active_orders, active_orders)
     |> assign(:total_revenue, total_revenue)
     |> assign(:is_admin, is_admin)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @group.name %>
      <:subtitle>Vue d'ensemble du groupe</:subtitle>
      <:actions>
        <.link patch={~p"/groups/#{@group.id}/edit"} phx-click={JS.push_focus()}>
          <.button>Modifier le groupe</.button>
        </.link>
      </:actions>
    </.header>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mt-8">
      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-building-office-2" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">QGs</h3>
        </div>
        <div class="text-2xl font-bold"><%= length(@headquarters_list) %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <.link navigate={~p"/groups/#{@group.id}/headquarters"} class="text-sm text-primary-600 hover:text-primary-700">
            Voir les QGs →
          </.link>
        </div>
      </div>

      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-cube" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Produits</h3>
        </div>
        <div class="text-2xl font-bold"><%= length(@items_list) %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <.link navigate={~p"/groups/#{@group.id}/items"} class="text-sm text-primary-600 hover:text-primary-700">
            Voir les produits →
          </.link>
        </div>
      </div>

      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-clipboard-document-list" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Commandes en cours</h3>
        </div>
        <div class="text-2xl font-bold"><%= length(@active_orders) %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <span class="text-sm text-zinc-500">Commandes en préparation ou en livraison</span>
        </div>
      </div>

      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-currency-euro" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Chiffre d'affaires</h3>
        </div>
        <div class="text-2xl font-bold"><%= Number.Currency.number_to_currency(@total_revenue, unit: "€") %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <span class="text-sm text-zinc-500">Total des ventes</span>
        </div>
      </div>
    </div>

    <div class="mt-8">
      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-map" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Carte des opérations</h3>
        </div>
        <.live_component
          module={SoSinpleWeb.MapComponent}
          id="group-map"
          headquarters={@headquarters_list}
          orders={@active_orders}
        />
      </div>
    </div>

    <div class="mt-8">
      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center gap-2">
            <.icon name="hero-truck" class="w-5 h-5 text-zinc-500" />
            <h3 class="text-lg font-semibold">Commandes à traiter</h3>
          </div>
          <div class="flex gap-2">
            <.button variant="outline" size="sm">
              <.icon name="hero-funnel" class="w-4 h-4 mr-1" /> Filtrer
            </.button>
            <.button variant="outline" size="sm">
              <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Actualiser
            </.button>
          </div>
        </div>

        <.table>
          <.table_head>
            <:col>Commande</:col>
            <:col>Statut</:col>
            <:col>QG</:col>
            <:col>Client</:col>
            <:col>Total</:col>
            <:col></:col>
          </.table_head>
          <.table_body>
            <.table_row :for={order <- @active_orders}>
              <:cell class="w-full">
                <div class="flex flex-col gap-0.5">
                  <span class="font-semibold">#<%= order.id %></span>
                  <span class="text-zinc-400 text-sm"><%= order.inserted_at %></span>
                </div>
              </:cell>
              <:cell>
                <%= case order.status do %>
                  <% "preparation" -> %>
                    <.badge color="blue">En préparation</.badge>
                  <% "pret" -> %>
                    <.badge color="green">Prêt</.badge>
                  <% "en_livraison" -> %>
                    <.badge color="purple">En livraison</.badge>
                  <% "livre" -> %>
                    <.badge color="green">Livré</.badge>
                  <% "annule" -> %>
                    <.badge color="red">Annulé</.badge>
                <% end %>
              </:cell>
              <:cell>
                <div class="flex items-center gap-2">
                  <.icon name="hero-building-office" class="w-4 h-4 text-zinc-400" />
                  <%= order.headquarters.name %>
                </div>
              </:cell>
              <:cell>
                <div class="flex items-center gap-2">
                  <.icon name="hero-user" class="w-4 h-4 text-zinc-400" />
                  <%= order.client_nom %>
                </div>
              </:cell>
              <:cell><%= Number.Currency.number_to_currency(order.prix_total, unit: "€") %></:cell>
              <:cell>
                <.dropdown>
                  <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                    <.icon name="hero-ellipsis-horizontal" class="size-5" />
                  </:toggle>
                  <.dropdown_link navigate={~p"/orders/#{order.id}"}>
                    <.icon name="hero-eye" class="w-4 h-4 mr-2" /> Voir
                  </.dropdown_link>
                  <.dropdown_link navigate={~p"/orders/#{order.id}/edit"}>
                    <.icon name="hero-pencil" class="w-4 h-4 mr-2" /> Modifier
                  </.dropdown_link>
                  <%= case order.status do %>
                    <% "preparation" -> %>
                      <.dropdown_link phx-click="mark_ready" phx-value-id={order.id}>
                        <.icon name="hero-check" class="w-4 h-4 mr-2" /> Marquer comme prêt
                      </.dropdown_link>
                    <% "pret" -> %>
                      <.dropdown_link phx-click="start_delivery" phx-value-id={order.id}>
                        <.icon name="hero-truck" class="w-4 h-4 mr-2" /> Commencer la livraison
                      </.dropdown_link>
                    <% "en_livraison" -> %>
                      <.dropdown_link phx-click="complete_delivery" phx-value-id={order.id}>
                        <.icon name="hero-flag" class="w-4 h-4 mr-2" /> Terminer la livraison
                      </.dropdown_link>
                  <% end %>
                  <%= unless order.status in ["livre", "annule"] do %>
                    <.dropdown_link phx-click="cancel_order" phx-value-id={order.id} class="text-red-600 hover:text-red-700">
                      <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Annuler la commande
                    </.dropdown_link>
                  <% end %>
                </.dropdown>
              </:cell>
            </.table_row>
          </.table_body>
        </.table>
      </div>
    </div>

    <.back navigate={~p"/groups"} class="mt-10">Retour aux groupes</.back>
    """
  end

  @impl true
  def handle_event("mark_ready", %{"id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "pret") do
      {:ok, _updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Commande marquée comme prête")
         |> assign(:active_orders, Orders.list_active_orders_by_group(socket.assigns.group.id))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Impossible de mettre à jour le statut de la commande")}
    end
  end

  @impl true
  def handle_event("start_delivery", %{"id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "en_livraison") do
      {:ok, _updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Commande en cours de livraison")
         |> assign(:active_orders, Orders.list_active_orders_by_group(socket.assigns.group.id))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Impossible de démarrer la livraison")}
    end
  end

  @impl true
  def handle_event("complete_delivery", %{"id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "livre") do
      {:ok, _updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Commande livrée avec succès")
         |> assign(:active_orders, Orders.list_active_orders_by_group(socket.assigns.group.id))
         |> assign(:total_revenue, Orders.calculate_total_revenue_for_group(socket.assigns.group.id))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Impossible de finaliser la livraison")}
    end
  end

  @impl true
  def handle_event("cancel_order", %{"id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "annule") do
      {:ok, _updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Commande annulée")
         |> assign(:active_orders, Orders.list_active_orders_by_group(socket.assigns.group.id))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Impossible d'annuler la commande")}
    end
  end
end
