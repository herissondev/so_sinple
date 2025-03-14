defmodule SoSinpleWeb.StockItemLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory
  alias SoSinple.Organizations
  alias SoSinple.Repo

  @impl true
  def mount(_params, _session, socket) do
    # Check if the current user is a manager of the headquarters
    can_manage_stock = Organizations.is_headquarters_manager?(
      socket.assigns.current_user.id,
      socket.assigns.current_headquarters.id
    )

    {:ok, assign(socket, can_manage_stock: can_manage_stock)}
  end

  @impl true
  def handle_params(%{"stock_item_id" => id}, _url, socket) do
    stock_item = Inventory.get_stock_item!(id) |> Repo.preload(:item)

    {:noreply,
     socket
     |> assign(:page_title, "Edit Stock Item")
     |> assign(:stock_item, stock_item)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Edit Stock Item
      <:subtitle>Update stock information for <%= @stock_item.item.name %></:subtitle>
    </.header>

    <.live_component
      module={SoSinpleWeb.StockItemLive.FormComponent}
      id={@stock_item.id}
      action={:edit}
      stock_item={@stock_item}
      patch={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items"}
      current_group={@current_group}
      current_headquarters={@current_headquarters}
    />

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters/#{@current_headquarters.id}/stock_items"}>
      Back to stock items
    </.back>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.StockItemLive.FormComponent, {:saved, _stock_item}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Stock item updated successfully")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.current_group.id}/headquarters/#{socket.assigns.current_headquarters.id}/stock_items")}
  end
end
