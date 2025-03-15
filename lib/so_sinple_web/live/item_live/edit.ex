defmodule SoSinpleWeb.ItemLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory
  alias SoSinple.Inventory.Item

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:ok,
     socket
     |> assign(:is_admin, is_admin)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    item = Inventory.get_item!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Edit Item - #{item.name}")
     |> assign(:item, item)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>

      <.live_component
        module={SoSinpleWeb.ItemLive.FormComponent}
        id={@item.id}
        title={@page_title}
        action={:edit}
        item={@item}
        current_group={@current_group}
        current_user={@current_user}
        is_admin={@is_admin}
        patch={~p"/groups/#{@current_group.id}/items"}
      />

      <.back navigate={~p"/groups/#{@current_group.id}/items"} class="mt-6">Back to items</.back>
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.ItemLive.FormComponent, {:saved, _item}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Item updated successfully")
     |> push_navigate(to: ~p"/groups/#{@current_group.id}/items")}
  end
end
