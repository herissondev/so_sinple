defmodule SoSinpleWeb.HeadquartersLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Inventory
  alias SoSinple.Orders

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => _group_id, "headquarter_id" => id}, _, socket) do
    # Le groupe et le QG sont déjà assignés par le hook check_headquarters_access
    headquarters = socket.assigns.current_headquarters
    stock_items = Inventory.list_stock_items_by_headquarters(id)
    |> Enum.sort_by(fn stock -> stock.item.name end)

    # Récupérer les items qui n'ont pas encore de stock dans ce QG
    group_items = Inventory.list_available_items_by_group(socket.assigns.current_group.id)
    existing_item_ids = Enum.map(stock_items, fn stock -> stock.item_id end)
    available_items = Enum.filter(group_items, fn item -> item.id not in existing_item_ids end)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    # Vérifier si des stocks sont en dessous du seuil d'alerte
    stocks_below_threshold = Enum.filter(stock_items, fn stock ->
      Inventory.StockItem.below_alert_threshold?(stock)
    end)

    # Récupérer les commandes actives et les statistiques du QG
    active_orders = Orders.list_active_orders_by_headquarters(id)
    headquarters_stats = Orders.get_headquarters_statistics(id)

    {:noreply,
     socket
     |> assign(:page_title, "QG: #{headquarters.name}")
     |> assign(:headquarters, headquarters)
     |> assign(:stock_items, stock_items)
     |> assign(:available_items, available_items)
     |> assign(:is_admin, is_admin)
     |> assign(:stocks_below_threshold, stocks_below_threshold)
     |> assign(:active_orders, active_orders)
     |> assign(:headquarters_stats, headquarters_stats)}
  end

  def handle_params(%{"group_id" => _group_id, "headquarter_id" => id, "live_action" => "edit"}, _, socket) do
    # Le groupe et le QG sont déjà assignés par le hook check_headquarters_access
    headquarters = socket.assigns.current_headquarters

    {:noreply,
     socket
     |> assign(:page_title, "Modifier #{headquarters.name}")
     |> assign(:headquarters, headquarters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @headquarters.name %>
      <:subtitle>Détails et statistiques du QG</:subtitle>
      <:actions>
        <.link patch={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/edit"} phx-click={JS.push_focus()}>
          <.button>Modifier le QG</.button>
        </.link>
      </:actions>
    </.header>

    <%= if length(@stocks_below_threshold) > 0 do %>
      <div class="my-6 bg-yellow-100 dark:bg-yellow-900 border-l-4 border-yellow-500 text-yellow-700 dark:text-yellow-300 p-4" role="alert">
        <p class="font-bold">⚠️ Alerte de stock</p>
        <p>Les produits suivants sont en dessous de leur seuil d'alerte :</p>
        <ul class="list-disc ml-5 mt-2">
          <%= for stock <- @stocks_below_threshold do %>
            <li>
              <strong><%= stock.item.name %></strong> :
              <%= stock.available_quantity %> unités disponibles
              (seuil : <%= stock.alert_threshold %>)
            </li>
          <% end %>
        </ul>
        <div class="mt-2">
          <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/stock_items"} class="text-sm font-medium text-yellow-800 dark:text-yellow-200 hover:underline">
            Gérer le stock →
          </.link>
        </div>
      </div>
    <% end %>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mt-8">
      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-currency-euro" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Chiffre d'affaires</h3>
        </div>
        <div class="text-2xl font-bold"><%= Number.Currency.number_to_currency(@headquarters_stats.total_revenue, unit: "€") %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <span class="text-sm text-zinc-500">Total des ventes</span>
        </div>
      </div>

      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-clipboard-document-list" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Commandes actives</h3>
        </div>
        <div class="text-2xl font-bold"><%= length(@active_orders) %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <span class="text-sm text-zinc-500">Commandes en traitement</span>
        </div>
      </div>

      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-cube" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Produits en stock</h3>
        </div>
        <div class="text-2xl font-bold"><%= length(@stock_items) %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <span class="text-sm text-zinc-500"><%= length(@stocks_below_threshold) %> produits en alerte</span>
          <div class="mt-1">
            <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/stock_items"} class="text-sm text-primary-600 hover:text-primary-700">
              Voir le stock →
            </.link>
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center mb-4">
          <.icon name="hero-check-badge" class="w-5 h-5 mr-2 text-zinc-500" />
          <h3 class="text-base font-semibold">Livraisons complétées</h3>
        </div>
        <div class="text-2xl font-bold"><%= @headquarters_stats.completed_count %></div>
        <div class="mt-4 pt-4 border-t border-zinc-200 dark:border-zinc-700">
          <span class="text-sm text-zinc-500">Commandes livrées</span>
        </div>
      </div>
    </div>

    <div class="mt-8">
      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-sm border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center gap-2">
            <.icon name="hero-chart-bar" class="w-5 h-5 text-zinc-500" />
            <h3 class="text-lg font-semibold">Statistiques détaillées</h3>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div class="p-4 bg-zinc-50 dark:bg-zinc-900 rounded-lg">
            <div class="text-sm text-zinc-500 mb-1">Valeur moyenne de commande</div>
            <div class="text-lg font-semibold"><%= Number.Currency.number_to_currency(@headquarters_stats.average_order_value, unit: "€") %></div>
          </div>
          <div class="p-4 bg-zinc-50 dark:bg-zinc-900 rounded-lg">
            <div class="text-sm text-zinc-500 mb-1">CA du mois en cours</div>
            <div class="text-lg font-semibold"><%= Number.Currency.number_to_currency(@headquarters_stats.current_month_revenue, unit: "€") %></div>
          </div>
          <div class="p-4 bg-zinc-50 dark:bg-zinc-900 rounded-lg">
            <div class="text-sm text-zinc-500 mb-1">Commandes en préparation</div>
            <div class="text-lg font-semibold"><%= @headquarters_stats.preparation_count %></div>
          </div>
          <div class="p-4 bg-zinc-50 dark:bg-zinc-900 rounded-lg">
            <div class="text-sm text-zinc-500 mb-1">Commandes prêtes</div>
            <div class="text-lg font-semibold"><%= @headquarters_stats.ready_count %></div>
          </div>
        </div>
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

        <%= if Enum.empty?(@active_orders) do %>
          <div class="text-center py-8 text-zinc-400">
            <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-4" />
            <p>Aucune commande active pour ce QG.</p>
          </div>
        <% else %>
          <.table>
            <.table_head>
              <:col>Commande</:col>
              <:col>Statut</:col>
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
        <% end %>
      </div>
    </div>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters"} class="mt-10">Retour aux QG</.back>
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
         |> assign(:active_orders, Orders.list_active_orders_by_headquarters(socket.assigns.headquarters.id))
         |> assign(:headquarters_stats, Orders.get_headquarters_statistics(socket.assigns.headquarters.id))}

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
         |> assign(:active_orders, Orders.list_active_orders_by_headquarters(socket.assigns.headquarters.id))
         |> assign(:headquarters_stats, Orders.get_headquarters_statistics(socket.assigns.headquarters.id))}

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
         |> assign(:active_orders, Orders.list_active_orders_by_headquarters(socket.assigns.headquarters.id))
         |> assign(:headquarters_stats, Orders.get_headquarters_statistics(socket.assigns.headquarters.id))}

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
         |> assign(:active_orders, Orders.list_active_orders_by_headquarters(socket.assigns.headquarters.id))
         |> assign(:headquarters_stats, Orders.get_headquarters_statistics(socket.assigns.headquarters.id))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Impossible d'annuler la commande")}
    end
  end
end
