defmodule SoSinpleWeb.ItemLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory

  @impl true
  def mount(_params, _session, socket) do
    # Le groupe et l'item sont déjà assignés par le hook check_item_access
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => _group_id, "item_id" => _item_id}, _, socket) do
    # L'item est déjà assigné par le hook check_item_access
    item = socket.assigns.current_item

    # Récupérer les stocks de cet item dans les différents QG
    stock_items = Inventory.list_stock_items_by_item(item.id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:noreply,
     socket
     |> assign(:page_title, "Item: #{item.name}")
     |> assign(:item, item)
     |> assign(:stock_items, stock_items)
     |> assign(:is_admin, is_admin)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @item.name %>
      <:subtitle>Item details and stock</:subtitle>
      <:actions>
        <%= if @is_admin do %>
          <.link patch={~p"/groups/#{@current_group.id}/items/#{@item.id}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit item</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="Name"><%= @item.name %></:item>
      <:item title="Description"><%= @item.description %></:item>
      <:item title="Price"><%= Number.Currency.number_to_currency(@item.price) %></:item>
      <:item title="Available"><%= @item.available %></:item>
      <:item :if={@item.image_url && @item.image_url != ""} title="Image">
        <img src={@item.image_url} alt={@item.name} class="w-32 h-32 object-cover rounded" />
      </:item>
    </.list>

    <.header class="mt-10">
      Stock in Headquarters
    </.header>

    <%= if Enum.empty?(@stock_items) do %>
      <div class="mt-4 text-center">
        <p class="text-gray-500">This item is not stocked in any headquarters yet.</p>
      </div>
    <% else %>
      <.table id="stock_items">
        <.table_head>
          <:col>Headquarters</:col>
          <:col>Available Quantity</:col>
          <:col>Alert Threshold</:col>
          <:col>Status</:col>
          <:col>Actions</:col>
          <:col></:col>
        </.table_head>
        <.table_body>
          <.table_row :for={stock <- @stock_items}>
            <:cell><%= stock.headquarters.name %></:cell>
            <:cell>
              <span class={if Inventory.StockItem.below_alert_threshold?(stock), do: "text-red-600 font-bold", else: ""}>
                <%= stock.available_quantity %>
              </span>
            </:cell>
            <:cell><%= stock.alert_threshold %></:cell>
            <:cell>
              <%= if Inventory.StockItem.below_alert_threshold?(stock) do %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                  Below Threshold
                </span>
              <% else %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  OK
                </span>
              <% end %>
            </:cell>
            <:cell>
              <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{stock.headquarters_id}/stock_items/#{stock.id}"}>
                View
              </.link>
            </:cell>
            <:cell>
              <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{stock.headquarters_id}/stock_items/#{stock.id}/edit"}>
                Edit
              </.link>
            </:cell>
          </.table_row>
        </.table_body>
      </.table>
    <% end %>

    <.back navigate={~p"/groups/#{@current_group.id}/items"} class="mt-10">Back to items</.back>

    """
  end
end
