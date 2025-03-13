defmodule SoSinpleWeb.HeadquartersLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Headquarters

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    # Le groupe est déjà assigné par le hook check_group_access
    headquarters_list = Organizations.list_headquarters_by_group(group_id)
    {:ok, stream(socket, :headquarters, headquarters_list)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Headquarters")
    |> assign(:headquarters, Organizations.get_headquarters!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Headquarters")
    |> assign(:headquarters, %Headquarters{group_id: socket.assigns.current_group.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Headquarters for #{socket.assigns.current_group.name}")
    |> assign(:headquarters, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.HeadquartersLive.FormComponent, {:saved, headquarters}}, socket) do
    {:noreply, stream_insert(socket, :headquarters, headquarters)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    headquarters = Organizations.get_headquarters!(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    if socket.assigns.current_group.admin_id == socket.assigns.current_user.id do
      {:ok, _} = Organizations.delete_headquarters(headquarters)
      {:noreply, stream_delete(socket, :headquarters, headquarters)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Only the group administrator can delete headquarters.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Headquarters for <%= @current_group.name %>
      <:actions>
        <.link patch={~p"/groups/#{@current_group.id}/headquarters/new"}>
          <.button>New Headquarters</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="headquarters"
      rows={@streams.headquarters}
      row_click={fn {_id, hq} -> JS.navigate(~p"/groups/#{@current_group.id}/headquarters/#{hq.id}") end}
    >
      <:col :let={{_id, hq}} label="Name"><%= hq.name %></:col>
      <:col :let={{_id, hq}} label="Address"><%= hq.address %></:col>
      <:col :let={{_id, hq}} label="Phone"><%= hq.phone %></:col>
      <:col :let={{_id, hq}} label="Active"><%= hq.active %></:col>
      <:action :let={{_id, hq}}>
        <div class="sr-only">
          <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{hq.id}"}>Show</.link>
        </div>
        <.link navigate={~p"/groups/#{@current_group.id}/headquarters/#{hq.id}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, hq}}>
        <%= if @current_group.admin_id == @current_user.id do %>
          <.link
            phx-click={JS.push("delete", value: %{id: hq.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        <% end %>
      </:action>
    </.table>

    <.back navigate={~p"/groups/#{@current_group.id}"} class="mt-6">Back to group</.back>

    <.modal :if={@live_action in [:new, :edit]} id="headquarters-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/headquarters")}>
      <.live_component
        module={SoSinpleWeb.HeadquartersLive.FormComponent}
        id={@headquarters.id || :new}
        title={@page_title}
        action={@live_action}
        headquarters={@headquarters}
        current_group={@current_group}
        patch={~p"/groups/#{@current_group.id}/headquarters"}
      />
    </.modal>
    """
  end
end
