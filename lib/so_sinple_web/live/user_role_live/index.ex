defmodule SoSinpleWeb.UserRoleLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.UserRole
  alias SoSinple.Accounts
  alias SoSinple.Repo

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    # Le groupe est déjà assigné par le hook check_user_roles_access
    user_roles = Organizations.list_user_roles_by_group(group_id)
    |> Repo.preload([:user, :headquarters])

    {:ok, stream(socket, :user_roles, user_roles)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User Role")
    |> assign(:user_role, Organizations.get_user_role!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User Role")
    |> assign(:user_role, %UserRole{group_id: socket.assigns.current_group.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "User Roles for #{socket.assigns.current_group.name}")
    |> assign(:user_role, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.UserRoleLive.FormComponent, {:saved, user_role}}, socket) do
    {:noreply, stream_insert(socket, :user_roles, user_role)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user_role = Organizations.get_user_role!(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    if socket.assigns.can_manage_roles do
      {:ok, _} = Organizations.delete_user_role(user_role)
      {:noreply, stream_delete(socket, :user_roles, user_role)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Only the group administrator can delete user roles.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      User Roles for <%= @current_group.name %>
      <:subtitle>
        <%= if @can_manage_roles do %>
          You can manage user roles for this group.
        <% else %>
          You can view but not modify user roles for this group.
        <% end %>
      </:subtitle>
      <:actions>
        <%= if @can_manage_roles do %>
          <.link patch={~p"/groups/#{@current_group.id}/user_roles/new"}>
            <.button>New User Role</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.table
      id="user_roles"
      rows={@streams.user_roles}
      row_click={fn {_id, user_role} -> JS.navigate(~p"/groups/#{@current_group.id}/user_roles/#{user_role.id}") end}
    >
      <:col :let={{_id, user_role}} label="User">
        <%= if user_role.user, do: user_role.user.email, else: "Unknown" %>
      </:col>
      <:col :let={{_id, user_role}} label="Role"><%= user_role.role %></:col>
      <:col :let={{_id, user_role}} label="Headquarters">
        <%= if user_role.headquarters, do: user_role.headquarters.name, else: "N/A" %>
      </:col>
      <:col :let={{_id, user_role}} label="Active"><%= user_role.active %></:col>
      <:action :let={{_id, user_role}}>
        <div class="sr-only">
          <.link navigate={~p"/groups/#{@current_group.id}/user_roles/#{user_role.id}"}>Show</.link>
        </div>
        <%= if @can_manage_roles do %>
          <.link navigate={~p"/groups/#{@current_group.id}/user_roles/#{user_role.id}/edit"}>Edit</.link>
        <% end %>
      </:action>
      <:action :let={{id, user_role}}>
        <%= if @can_manage_roles do %>
          <.link
            phx-click={JS.push("delete", value: %{id: user_role.id}) |> hide("##{id}")}
            data-confirm="Are you sure you want to delete this user role?"
          >
            Delete
          </.link>
        <% end %>
      </:action>
    </.table>

    <.back navigate={~p"/groups/#{@current_group.id}"} class="mt-6">Back to group</.back>

    <.modal :if={@live_action in [:new, :edit]} id="user_role-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/user_roles")}>
      <.live_component
        module={SoSinpleWeb.UserRoleLive.FormComponent}
        id={@user_role.id || :new}
        title={@page_title}
        action={@live_action}
        user_role={@user_role}
        current_group={@current_group}
        current_user={@current_user}
        can_manage_roles={@can_manage_roles}
        patch={~p"/groups/#{@current_group.id}/user_roles"}
      />
    </.modal>
    """
  end
end
