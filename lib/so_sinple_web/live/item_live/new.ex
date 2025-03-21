defmodule SoSinpleWeb.ItemLive.New do
  use SoSinpleWeb, :live_view

  alias SoSinple.Inventory
  alias SoSinple.Inventory.Item

  @impl true
  def mount(_params, _session, socket) do
    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:ok,
     socket
     |> assign(:is_admin, is_admin)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    item = %Item{group_id: socket.assigns.current_group.id}

    {:noreply,
     socket
     |> assign(:page_title, "New Item for #{socket.assigns.current_group.name}")
     |> assign(:item, item)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="m-auto h-full">

      <.live_component
        module={SoSinpleWeb.ItemLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
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
     |> put_flash(:info, "Item created successfully")
     |> push_navigate(to: ~p"/groups/#{@current_group.id}/items")}
  end
end
