defmodule SoSinpleWeb.StockItemLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory
  alias SoSinple.Inventory.StockItem
  alias SoSinple.Organizations

  @impl true
  def mount(%{"group_id" => _group_id, "headquarter_id" => headquarter_id}, _session, socket) do
    # Le groupe et le QG sont déjà assignés par le hook check_headquarters_access
    stock_items = Inventory.list_stock_items_by_headquarters(headquarter_id)
    |> Enum.sort_by(fn stock -> stock.item.name end)

    # Récupérer les items qui n'ont pas encore de stock dans ce QG
    group_items = Inventory.list_available_items_by_group(socket.assigns.current_group.id)
    existing_item_ids = Enum.map(stock_items, fn stock -> stock.item_id end)
    available_items = Enum.filter(group_items, fn item -> item.id not in existing_item_ids end)

    # Vérifier si l'utilisateur est l'administrateur du groupe ou le responsable du QG
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id
    is_hq_manager = Organizations.is_headquarters_manager?(socket.assigns.current_user.id, headquarter_id)
    can_manage_stock = is_admin || is_hq_manager

    # Vérifier si des stocks sont en dessous du seuil d'alerte
    stocks_below_threshold = Enum.filter(stock_items, fn stock ->
      Inventory.StockItem.below_alert_threshold?(stock)
    end)

    {:ok,
     socket
     |> assign(:is_admin, is_admin)
     |> assign(:is_hq_manager, is_hq_manager)
     |> assign(:can_manage_stock, can_manage_stock)
     |> assign(:available_items, available_items)
     |> assign(:stocks_below_threshold, stocks_below_threshold)
     |> assign(:stock_items, stock_items)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Stock Item")
    |> assign(:stock_item, Inventory.get_stock_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Stock Item")
    |> assign(:stock_item, %StockItem{
      headquarters_id: socket.assigns.current_headquarters.id,
      available_quantity: 0,
      alert_threshold: 10
    })
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Stock for #{socket.assigns.current_headquarters.name}")
    |> assign(:stock_item, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.StockItemLive.FormComponent, {:saved, _stock_item}}, socket) do
    stock_items = Inventory.list_stock_items_by_headquarters(socket.assigns.current_headquarters.id)
    |> Enum.sort_by(fn stock -> stock.item.name end)

    stocks_below_threshold = Enum.filter(stock_items, fn stock ->
      Inventory.StockItem.below_alert_threshold?(stock)
    end)

    {:noreply,
     socket
     |> assign(:stock_items, stock_items)
     |> assign(:stocks_below_threshold, stocks_below_threshold)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    stock_item = Inventory.get_stock_item!(id)

    # Vérifier si l'utilisateur peut gérer le stock
    if socket.assigns.can_manage_stock do
      {:ok, _} = Inventory.delete_stock_item(stock_item)

      stock_items = Inventory.list_stock_items_by_headquarters(socket.assigns.current_headquarters.id)
      |> Enum.sort_by(fn stock -> stock.item.name end)

      stocks_below_threshold = Enum.filter(stock_items, fn stock ->
        Inventory.StockItem.below_alert_threshold?(stock)
      end)

      {:noreply,
       socket
       |> assign(:stock_items, stock_items)
       |> assign(:stocks_below_threshold, stocks_below_threshold)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You don't have permission to delete stock items.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Stock for <%= @current_headquarters.name %>
      <:subtitle>
        <%= cond do %>
          <% @is_admin -> %>
            You can manage stock for this headquarters as group administrator.
          <% @is_hq_manager -> %>
            You can manage stock for this headquarters as headquarters manager.
          <% true -> %>
            You can view but not modify stock for this headquarters.
        <% end %>
      </:subtitle>
      <:actions>
        <%= if @can_manage_stock && length(@available_items) > 0 do %>
          <.link patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items/new"}>
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

    <.table>
      <.table_head>
        <:col>Item</:col>
        <:col>Available Quantity</:col>
        <:col>Alert Threshold</:col>
        <:col>Status</:col>
        <:col></:col>
      </.table_head>
      <.table_body>
        <.table_row :for={stock_item <- @stock_items}>
          <:cell class="w-full flex items-center gap-2">
            <%= if stock_item.item.image_url && stock_item.item.image_url != "" do %>
              <img src={stock_item.item.image_url} class="size-9 rounded-full" />
            <% end %>
            <div class="flex flex-col gap-0.5">
              <span class="font-semibold"><%= stock_item.item.name %></span>
              <span class="text-zinc-400 text-sm/3"><%= stock_item.item.description %></span>
            </div>
          </:cell>
          <:cell>
            <span class={if Inventory.StockItem.below_alert_threshold?(stock_item), do: "text-red-600 font-bold", else: ""}>
              <%= stock_item.available_quantity %>
            </span>
          </:cell>
          <:cell><%= stock_item.alert_threshold %></:cell>
          <:cell>
            <%= if Inventory.StockItem.below_alert_threshold?(stock_item) do %>
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
              <.dropdown_link navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items/#{stock_item.id}"}>
                View
              </.dropdown_link>
              <%= if @can_manage_stock do %>
                <.dropdown_link patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items/#{stock_item.id}/edit"}>
                  Edit
                </.dropdown_link>
                <.dropdown_link
                  phx-click={JS.push("delete", value: %{id: stock_item.id})}
                  data-confirm="Are you sure you want to delete this stock item?">
                  Delete
                </.dropdown_link>
              <% end %>
            </.dropdown>
          </:cell>
        </.table_row>
      </.table_body>
    </.table>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}"} class="mt-6">Back to headquarters</.back>

    <.modal :if={@live_action in [:new, :edit]} id="stock_item-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items")}>
      <.live_component
        module={SoSinpleWeb.StockItemLive.FormComponent}
        id={@stock_item.id || :new}
        title={@page_title}
        action={@live_action}
        stock_item={@stock_item}
        current_group={@current_group}
        current_headquarters={@current_headquarters}
        current_user={@current_user}
        is_admin={@is_admin}
        is_hq_manager={@is_hq_manager}
        can_manage_stock={@can_manage_stock}
        available_items={@available_items}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items"}
      />
    </.modal>
    """
  end
end
