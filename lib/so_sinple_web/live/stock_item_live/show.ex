defmodule SoSinpleWeb.StockItemLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory
  alias SoSinple.Organizations

  @impl true
  def mount(_params, _session, socket) do
    # Le groupe, le QG et le stock sont déjà assignés par le hook check_stock_item_access
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => _group_id, "headquarter_id" => headquarter_id, "stock_item_id" => stock_item_id}, _, socket) do
    # Le stock est déjà assigné par le hook check_stock_item_access
    stock_item = Inventory.get_stock_item_with_associations!(stock_item_id)

    # Vérifier si l'utilisateur est l'administrateur du groupe ou le responsable du QG
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id
    is_hq_manager = Organizations.is_headquarters_manager?(socket.assigns.current_user.id, headquarter_id)
    can_manage_stock = is_admin || is_hq_manager

    # Vérifier si le stock est en dessous du seuil d'alerte
    below_threshold = Inventory.StockItem.below_alert_threshold?(stock_item)

    {:noreply,
     socket
     |> assign(:page_title, "Stock Item: #{stock_item.item.name}")
     |> assign(:stock_item, stock_item)
     |> assign(:is_admin, is_admin)
     |> assign(:is_hq_manager, is_hq_manager)
     |> assign(:can_manage_stock, can_manage_stock)
     |> assign(:below_threshold, below_threshold)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Stock Item: <%= @stock_item.item.name %>
      <:subtitle>Stock details</:subtitle>
      <:actions>
        <%= if @can_manage_stock do %>
          <.link patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items/#{@stock_item.id}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit stock item</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="Item"><%= @stock_item.item.name %></:item>
      <:item title="Description"><%= @stock_item.item.description %></:item>
      <:item title="Headquarters"><%= @current_headquarters.name %></:item>
      <:item title="Available Quantity">
        <span class={if @below_threshold, do: "text-red-600 font-bold", else: ""}>
          <%= @stock_item.available_quantity %>
        </span>
      </:item>
      <:item title="Alert Threshold"><%= @stock_item.alert_threshold %></:item>
      <:item title="Status">
        <%= if @below_threshold do %>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
            Below Threshold
          </span>
        <% else %>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
            OK
          </span>
        <% end %>
      </:item>
      <:item :if={@stock_item.item.image_url && @stock_item.item.image_url != ""} title="Image">
        <img src={@stock_item.item.image_url} alt={@stock_item.item.name} class="w-32 h-32 object-cover rounded" />
      </:item>
    </.list>

    <.header class="mt-10">
      Stock Management
      <:subtitle>
        <%= cond do %>
          <% @is_admin -> %>
            Vous pouvez gérer les niveaux de stock en tant qu'administrateur de groupe.
          <% @is_hq_manager -> %>
            Vous pouvez gérer les niveaux de stock en tant que responsable du QG.
          <% true -> %>
            Seuls les administrateurs peuvent gérer les niveaux de stock.
        <% end %>
      </:subtitle>
    </.header>

    <%= if @can_manage_stock do %>
      <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="p-4 border rounded-lg shadow-sm">
          <h3 class="text-lg font-semibold mb-2">Add Stock</h3>
          <p class="text-sm text-gray-600 mb-4">Increase the available quantity of this item.</p>
          <form phx-submit="add_stock" class="flex items-end gap-2">
            <div>
              <label for="quantity" class="block text-sm font-medium text-gray-700 mb-1">Quantity</label>
              <input type="number" name="quantity" id="quantity" min="1" value="1" class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
            </div>
            <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
              Ajouter
            </button>
          </form>
        </div>

        <div class="p-4 border rounded-lg shadow-sm">
          <h3 class="text-lg font-semibold mb-2">Remove Stock</h3>
          <p class="text-sm text-gray-600 mb-4">Decrease the available quantity of this item.</p>
          <form phx-submit="remove_stock" class="flex items-end gap-2">
            <div>
              <label for="quantity" class="block text-sm font-medium text-gray-700 mb-1">Quantity</label>
              <input type="number" name="quantity" id="quantity" min="1" max={@stock_item.available_quantity} value="1" class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
            </div>
            <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
              Retirer
            </button>
          </form>
        </div>
      </div>
    <% else %>
      <div class="mt-4 p-4 bg-gray-50 rounded-lg">
        <p class="text-gray-600">You don't have permission to manage stock levels.</p>
      </div>
    <% end %>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items"} class="mt-10">Back to stock items</.back>

    <.modal :if={@live_action == :edit} id="stock_item-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items/#{@stock_item.id}")}>
      <.live_component
        module={SoSinpleWeb.StockItemLive.FormComponent}
        id={@stock_item.id}
        title={@page_title}
        action={@live_action}
        stock_item={@stock_item}
        current_group={@current_group}
        current_headquarters={@current_headquarters}
        current_user={@current_user}
        is_admin={@is_admin}
        is_hq_manager={@is_hq_manager}
        can_manage_stock={@can_manage_stock}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items/#{@stock_item.id}"}
      />
    </.modal>
    """
  end

  @impl true
  def handle_event("add_stock", %{"quantity" => quantity}, socket) do
    if socket.assigns.can_manage_stock do
      quantity = String.to_integer(quantity)
      stock_item = socket.assigns.stock_item

      case Inventory.adjust_stock_quantity(stock_item, quantity) do
        {:ok, updated_stock_item} ->
          {:noreply,
           socket
           |> put_flash(:info, "Added #{quantity} items to stock.")
           |> assign(:stock_item, updated_stock_item)
           |> assign(:below_threshold, Inventory.StockItem.below_alert_threshold?(updated_stock_item))}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to add stock.")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "You don't have permission to manage stock levels.")}
    end
  end

  @impl true
  def handle_event("remove_stock", %{"quantity" => quantity}, socket) do
    if socket.assigns.can_manage_stock do
      quantity = String.to_integer(quantity)
      stock_item = socket.assigns.stock_item

      case Inventory.adjust_stock_quantity(stock_item, -quantity) do
        {:ok, updated_stock_item} ->
          {:noreply,
           socket
           |> put_flash(:info, "Removed #{quantity} items from stock.")
           |> assign(:stock_item, updated_stock_item)
           |> assign(:below_threshold, Inventory.StockItem.below_alert_threshold?(updated_stock_item))}

        {:error, :insufficient_stock} ->
          {:noreply,
           socket
           |> put_flash(:error, "Insufficient stock available.")}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to remove stock.")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "You don't have permission to manage stock levels.")}
    end
  end
end
