defmodule SoSinpleWeb.HeadquartersLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Inventory

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

    {:noreply,
     socket
     |> assign(:page_title, "Headquarters: #{headquarters.name}")
     |> assign(:headquarters, headquarters)
     |> assign(:stock_items, stock_items)
     |> assign(:available_items, available_items)
     |> assign(:is_admin, is_admin)
     |> assign(:stocks_below_threshold, stocks_below_threshold)}
  end

  def handle_params(%{"group_id" => _group_id, "headquarter_id" => id, "live_action" => "edit"}, _, socket) do
    # Le groupe et le QG sont déjà assignés par le hook check_headquarters_access
    headquarters = socket.assigns.current_headquarters

    {:noreply,
     socket
     |> assign(:page_title, "Edit #{headquarters.name}")
     |> assign(:headquarters, headquarters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @headquarters.name %>
      <:subtitle>Headquarters details and stock</:subtitle>
      <:actions>
        <.link patch={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit headquarters</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Name"><%= @headquarters.name %></:item>
      <:item title="Address"><%= @headquarters.address %></:item>
      <:item title="Phone"><%= @headquarters.phone %></:item>
      <:item title="Active"><%= @headquarters.active %></:item>
      <:item title="Group"><%= @current_group.name %></:item>
    </.list>

    <.header class="mt-10">
      Stock Items
      <:actions>
        <%= if @is_admin && length(@available_items) > 0 do %>
          <.link patch={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/stock_items/new"}>
            <.button>Add Item to Stock</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <%= if length(@stocks_below_threshold) > 0 do %>
      <div class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-4" role="alert">
        <p class="font-bold">Stock Alert</p>
        <p>The following items are below their alert threshold:</p>
        <ul class="list-disc ml-5 mt-2">
          <%= for stock <- @stocks_below_threshold do %>
            <li>
              <strong><%= stock.item.name %></strong>:
              <%= stock.available_quantity %> units available
              (threshold: <%= stock.alert_threshold %>)
            </li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <%= if Enum.empty?(@stock_items) do %>
      <div class="mt-4 text-center">
        <p class="text-gray-500">No stock items found for this headquarters.</p>
        <p class="text-sm text-gray-400 mt-2">Add items to stock to get started.</p>
      </div>
    <% else %>
      <.table>
        <.table_head>
          <:col>Item</:col>
          <:col>Available Quantity</:col>
          <:col>Alert Threshold</:col>
          <:col>Status</:col>
          <:col></:col>
        </.table_head>
        <.table_body>
          <.table_row :for={stock <- @stock_items}>
            <:cell class="w-full flex items-center gap-2">
              <%= if stock.item.image_url && stock.item.image_url != "" do %>
                <img src={stock.item.image_url} class="size-9 rounded-full" />
              <% end %>
              <div class="flex flex-col gap-0.5">
                <span class="font-semibold"><%= stock.item.name %></span>
                <span class="text-zinc-400 text-sm/3"><%= stock.item.description %></span>
              </div>
            </:cell>
            <:cell>
              <span class={if Inventory.StockItem.below_alert_threshold?(stock), do: "text-red-600 font-bold", else: ""}>
                <%= stock.available_quantity %>
              </span>
            </:cell>
            <:cell><%= stock.alert_threshold %></:cell>
            <:cell>
              <%= if Inventory.StockItem.below_alert_threshold?(stock) do %>
                <.badge color="red">Below Threshold</.badge>
              <% else %>
                <.badge color="green">OK</.badge>
              <% end %>
            </:cell>
            <:cell>
              <.dropdown>
                <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                  <.icon name="hero-ellipsis-horizontal" class="size-5" />
                </:toggle>
                <.dropdown_link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/stock_items/#{stock.id}"}>
                  View
                </.dropdown_link>
                <.dropdown_link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}/stock_items/#{stock.id}/edit"}>
                  Edit
                </.dropdown_link>
              </.dropdown>
            </:cell>
          </.table_row>
        </.table_body>
      </.table>
    <% end %>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters"} class="mt-10">Back to headquarters</.back>
    """
  end
end
