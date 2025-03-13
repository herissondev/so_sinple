defmodule SoSinpleWeb.GroupLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => id}, _, socket) do
    group = Organizations.get_group_with_admin!(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    can_edit = group.admin_id == socket.assigns.current_user.id

    {:noreply,
     socket
     |> assign(:page_title, "Edit Group")
     |> assign(:group, group)
     |> assign(:can_edit, can_edit)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Edit Group
      <:subtitle>
        <%= if @can_edit do %>
          You can edit this group as you are the administrator.
        <% else %>
          You can view but not edit this group as you are not the administrator.
        <% end %>
      </:subtitle>
      <:actions>
        <.link navigate={~p"/groups/#{@group.id}"}>
          <.button>Back to Group</.button>
        </.link>
      </:actions>
    </.header>

    <%= if @can_edit do %>
      <.live_component
        module={SoSinpleWeb.GroupLive.FormComponent}
        id={@group.id}
        title={@page_title}
        action={:edit}
        group={@group}
        current_user={@current_user}
        patch={~p"/groups/#{@group.id}"}
      />
    <% else %>
      <div class="alert alert-warning">
        <p>You do not have permission to edit this group. Only the group administrator can edit it.</p>
      </div>

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
    <% end %>
    """
  end
end
