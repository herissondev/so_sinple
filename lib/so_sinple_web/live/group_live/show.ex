defmodule SoSinpleWeb.GroupLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => id}, _, socket) do
    group = Organizations.get_group_with_admin!(id)
    headquarters_list = Organizations.list_headquarters_by_group(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    is_admin = group.admin_id == socket.assigns.current_user.id

    {:noreply,
     socket
     |> assign(:page_title, "Group: #{group.name}")
     |> assign(:group, group)
     |> assign(:headquarters_list, headquarters_list)
     |> assign(:is_admin, is_admin)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @group.name %>
      <:subtitle>Group details and headquarters</:subtitle>
      <:actions>
        <.link patch={~p"/groups/#{@group.id}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit group</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Name"><%= @group.name %></:item>
      <:item title="Description"><%= @group.description %></:item>
      <:item title="Active"><%= @group.active %></:item>
      <:item title="Administrator">
        <%= if @group.admin do %>
          <%= @group.admin.email %>
        <% else %>
          No administrator assigned
        <% end %>
      </:item>
    </.list>

    <.header class="mt-10">
      Headquarters
      <:actions>
        <.link navigate={~p"/groups/#{@group.id}/headquarters/new"}>
          <.button>New Headquarters</.button>
        </.link>
      </:actions>
    </.header>

    <%= if Enum.empty?(@headquarters_list) do %>
      <div class="mt-4 text-center">
        <p class="text-gray-500">No headquarters found for this group.</p>
        <p class="text-sm text-gray-400 mt-2">Create a new headquarters to get started.</p>
      </div>
    <% else %>
      <.table id="headquarters" rows={@headquarters_list}>
        <:col :let={hq} label="Name"><%= hq.name %></:col>
        <:col :let={hq} label="Address"><%= hq.address %></:col>
        <:col :let={hq} label="Phone"><%= hq.phone %></:col>
        <:col :let={hq} label="Active"><%= hq.active %></:col>
        <:action :let={hq}>
          <.link navigate={~p"/groups/#{@group.id}/headquarters/#{hq.id}"}>View</.link>
        </:action>
        <:action :let={hq}>
          <.link navigate={~p"/groups/#{@group.id}/headquarters/#{hq.id}/edit"}>Edit</.link>
        </:action>
      </.table>
    <% end %>

    <.header class="mt-10">
      User Roles
      <:actions>
        <%= if @is_admin do %>
          <.link navigate={~p"/groups/#{@group.id}/user_roles/new"}>
            <.button>New User Role</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <div class="mt-4">
      <.link navigate={~p"/groups/#{@group.id}/user_roles"} class="text-blue-600 hover:text-blue-800">
        Manage User Roles →
      </.link>
    </div>

    <.back navigate={~p"/groups"} class="mt-10">Back to groups</.back>
    """
  end
end
