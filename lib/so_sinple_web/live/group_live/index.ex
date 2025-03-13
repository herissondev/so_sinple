defmodule SoSinpleWeb.GroupLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Group

  @impl true
  def mount(_params, _session, socket) do
    # Récupérer uniquement les groupes de l'utilisateur connecté
    user_groups = Organizations.list_user_groups(socket.assigns.current_user.id)
    {:ok, stream(socket, :groups, user_groups)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Group")
    |> assign(:group, Organizations.get_group!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Group")
    |> assign(:group, %Group{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Groups")
    |> assign(:group, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.GroupLive.FormComponent, {:saved, group}}, socket) do
    {:noreply, stream_insert(socket, :groups, group)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    group = Organizations.get_group!(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    if group.admin_id == socket.assigns.current_user.id do
      {:ok, _} = Organizations.delete_group(group)
      {:noreply, stream_delete(socket, :groups, group)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Only the group administrator can delete a group.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      My Groups
      <:actions>
        <.link patch={~p"/groups/new"}>
          <.button>New Group</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="groups"
      rows={@streams.groups}
      row_click={fn {_id, group} -> JS.navigate(~p"/groups/#{group.id}") end}
    >
      <:col :let={{_id, group}} label="Name"><%= group.name %></:col>
      <:col :let={{_id, group}} label="Description"><%= group.description %></:col>
      <:col :let={{_id, group}} label="Active"><%= group.active %></:col>
      <:col :let={{_id, group}} label="Role">
        <%= if group.admin_id == @current_user.id do %>
          Administrator
        <% else %>
          Member
        <% end %>
      </:col>
      <:action :let={{_id, group}}>
        <div class="sr-only">
          <.link navigate={~p"/groups/#{group.id}"}>Show</.link>
        </div>
        <.link patch={~p"/groups/#{group.id}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, group}}>
        <%= if group.admin_id == @current_user.id do %>
          <.link
            phx-click={JS.push("delete", value: %{id: group.id}) |> hide("##{id}")}
            data-confirm="Are you sure? This will delete the group and all associated data."
          >
            Delete
          </.link>
        <% end %>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="group-modal" show on_cancel={JS.patch(~p"/groups")}>
      <.live_component
        module={SoSinpleWeb.GroupLive.FormComponent}
        id={@group.id || :new}
        title={@page_title}
        action={@live_action}
        group={@group}
        current_user={@current_user}
        patch={~p"/groups"}
      />
    </.modal>
    """
  end
end
