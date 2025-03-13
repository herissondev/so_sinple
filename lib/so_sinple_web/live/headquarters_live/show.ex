defmodule SoSinpleWeb.HeadquartersLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations

  @impl true
  def mount(_params, _session, socket) do
    # Le groupe et le QG sont déjà assignés par le hook check_headquarters_access
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => _group_id, "headquarters_id" => headquarters_id}, _, socket) do
    # Précharger le groupe pour avoir toutes les informations
    headquarters = Organizations.get_headquarters_with_group!(headquarters_id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:noreply,
     socket
     |> assign(:page_title, "Headquarters: #{headquarters.name}")
     |> assign(:headquarters, headquarters)
     |> assign(:is_admin, is_admin)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @headquarters.name %>
      <:subtitle>Headquarters details</:subtitle>
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
      <:item title="Latitude"><%= @headquarters.latitude %></:item>
      <:item title="Longitude"><%= @headquarters.longitude %></:item>
      <:item title="Active"><%= @headquarters.active %></:item>
      <:item title="Group"><%= @current_group.name %></:item>
    </.list>

    <.back navigate={~p"/groups/#{@current_group.id}/headquarters"} class="mt-10">Back to headquarters</.back>

    <.modal :if={@live_action == :edit} id="headquarters-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}")}>
      <.live_component
        module={SoSinpleWeb.HeadquartersLive.FormComponent}
        id={@headquarters.id}
        title={@page_title}
        action={@live_action}
        headquarters={@headquarters}
        current_group={@current_group}
        patch={~p"/groups/#{@current_group.id}/headquarters/#{@headquarters.id}"}
      />
    </.modal>
    """
  end
end
