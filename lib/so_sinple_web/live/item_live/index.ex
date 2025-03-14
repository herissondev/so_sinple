defmodule SoSinpleWeb.ItemLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory
  alias SoSinple.Inventory.Item

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    # Le groupe est déjà assigné par le hook check_group_access
    items = Inventory.list_items_by_group(group_id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:ok,
     socket
     |> assign(:is_admin, is_admin)
     |> assign(:items, items)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:item, Inventory.get_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{group_id: socket.assigns.current_group.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Items for #{socket.assigns.current_group.name}")
    |> assign(:item, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.ItemLive.FormComponent, {:saved, item}}, socket) do
    items = Inventory.list_items_by_group(socket.assigns.current_group.id)
    {:noreply, assign(socket, :items, items)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Inventory.get_item!(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    if socket.assigns.is_admin do
      {:ok, _} = Inventory.delete_item(item)
      items = Inventory.list_items_by_group(socket.assigns.current_group.id)
      {:noreply, assign(socket, :items, items)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Only the group administrator can delete items.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Items for <%= @current_group.name %>
      <:subtitle>
        <%= if @is_admin do %>
          You can manage items for this group.
        <% else %>
          You can view but not modify items for this group.
        <% end %>
      </:subtitle>
      <:actions>
        <%= if @is_admin do %>
          <.link navigate={~p"/groups/#{@current_group.id}/items/new"}>
            <.button>New Item</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.table>
      <.table_head>
        <:col>Item</:col>
        <:col>Description</:col>
        <:col>Price</:col>
        <:col>Available</:col>
        <:col></:col>
      </.table_head>
      <.table_body>
        <.table_row :for={item <- @items}>
          <:cell class="w-full flex items-center gap-2">
            <%= if item.image_url && item.image_url != "" do %>
              <img src={item.image_url} class="size-9 rounded-full" />
            <% end %>
            <div class="flex flex-col gap-0.5">
              <span class="font-semibold"><%= item.name %></span>
            </div>
          </:cell>
          <:cell>
            <span class="text-zinc-400 text-sm/3"><%= item.description %></span>
          </:cell>
          <:cell><%= Number.Currency.number_to_currency(item.price) %></:cell>
          <:cell>
            <%= if item.available do %>
              <.badge color="green">Yes</.badge>
            <% else %>
              <.badge color="red">No</.badge>
            <% end %>
          </:cell>
          <:cell>
            <.dropdown>
              <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                <.icon name="hero-ellipsis-horizontal" class="size-5" />
              </:toggle>
              <.dropdown_link navigate={~p"/groups/#{@current_group.id}/items/#{item.id}"}>
                View
              </.dropdown_link>
              <%= if @is_admin do %>
                <.dropdown_link navigate={~p"/groups/#{@current_group.id}/items/#{item.id}/edit"}>
                  Edit
                </.dropdown_link>
                <.dropdown_link
                  phx-click={JS.push("delete", value: %{id: item.id})}
                  data-confirm="Are you sure you want to delete this item?">
                  Delete
                </.dropdown_link>
              <% end %>
            </.dropdown>
          </:cell>
        </.table_row>
      </.table_body>
    </.table>

    <.back navigate={~p"/groups/#{@current_group.id}"} class="mt-6">Back to group</.back>
    """
  end
end
