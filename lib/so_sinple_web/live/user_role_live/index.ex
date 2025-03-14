defmodule SoSinpleWeb.UserRoleLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.UserRole
  alias SoSinple.Repo

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    user_roles = Organizations.list_user_roles_by_group(group_id)
                 |> Repo.preload([:user])

    # Check if the current user is the admin of the group
    can_manage_roles = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:ok,
     socket
     |> assign(:user_roles, user_roles)
     |> assign(:can_manage_roles, can_manage_roles)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "User Roles")
    |> assign(:user_role, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.UserRoleLive.FormComponent, {:saved, _user_role}}, socket) do
    user_roles = Organizations.list_user_roles_by_group(socket.assigns.current_group.id)
                 |> Repo.preload([:user])
    {:noreply, assign(socket, :user_roles, user_roles)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user_role = Organizations.get_user_role!(id)

    if socket.assigns.can_manage_roles do
      {:ok, _} = Organizations.delete_user_role(user_role)

      user_roles = Organizations.list_user_roles_by_group(socket.assigns.current_group.id)
                   |> Repo.preload([:user])

      {:noreply,
       socket
       |> put_flash(:info, "User role deleted successfully")
       |> assign(:user_roles, user_roles)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Only the group administrator can delete user roles")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      User Roles for <%= @current_group.name %>
      <:subtitle>
        <%= if @can_manage_roles do %>
          Manage members and their roles in this group
        <% else %>
          View members and their roles in this group
        <% end %>
      </:subtitle>
      <:actions>
        <%= if @can_manage_roles do %>
          <.link navigate={~p"/groups/#{@current_group.id}/user_roles/new"}>
            <.button>Add Member</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.table>
      <.table_head>
        <:col>User</:col>
        <:col>Role</:col>
        <:col>Status</:col>
        <:col></:col>
      </.table_head>
      <.table_body>
        <.table_row :for={user_role <- @user_roles}>
          <:cell>
            <div class="font-semibold"><%= if user_role.user, do: user_role.user.email, else: "Unknown" %></div>
          </:cell>
          <:cell>
            <span class="text-zinc-400 text-sm/3"><%= String.capitalize(user_role.role) %></span>
          </:cell>
          <:cell>
            <%= if user_role.active do %>
              <.badge color="green">Active</.badge>
            <% else %>
              <.badge color="red">Inactive</.badge>
            <% end %>
          </:cell>
          <:cell>
            <%= if @can_manage_roles do %>
              <.dropdown>
                <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                  <.icon name="hero-ellipsis-horizontal" class="size-5" />
                </:toggle>
                <.dropdown_link navigate={~p"/groups/#{@current_group.id}/user_roles/#{user_role.id}"}>
                  View
                </.dropdown_link>
                <.dropdown_link navigate={~p"/groups/#{@current_group.id}/user_roles/#{user_role.id}/edit"}>
                  Edit
                </.dropdown_link>
                <.dropdown_link
                  phx-click={JS.push("delete", value: %{id: user_role.id})}
                  data-confirm="Are you sure you want to remove this member?">
                  Delete
                </.dropdown_link>
              </.dropdown>
            <% end %>
          </:cell>
        </.table_row>
      </.table_body>
    </.table>

    <.back navigate={~p"/groups/#{@current_group.id}"} class="mt-6">Back to group</.back>
    """
  end
end
