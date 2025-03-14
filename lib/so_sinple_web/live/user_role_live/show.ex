defmodule SoSinpleWeb.UserRoleLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Repo

  @impl true
  def mount(%{"user_role_id" => id}, _session, socket) do
    user_role = Organizations.get_user_role!(id) |> Repo.preload([:user])

    # Check if the current user is the admin of the group
    can_manage_roles = socket.assigns.current_group.admin_id == socket.assigns.current_user.id

    {:ok,
     socket
     |> assign(:user_role, user_role)
     |> assign(:can_manage_roles, can_manage_roles)}
  end

  @impl true
  def handle_params(%{"user_role_id" => id}, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "User Role Details")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      User Role Details
      <:subtitle>Member information for <%= @current_group.name %></:subtitle>
      <:actions>
        <%= if @can_manage_roles do %>
          <.link navigate={~p"/groups/#{@current_group.id}/user_roles/#{@user_role.id}/edit"}>
            <.button>Edit</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="User"><%= if @user_role.user, do: @user_role.user.email, else: "Unknown" %></:item>
      <:item title="Role"><%= String.capitalize(@user_role.role) %></:item>
      <:item title="Status">
        <%= if @user_role.active do %>
          <.badge color="green">Active</.badge>
        <% else %>
          <.badge color="red">Inactive</.badge>
        <% end %>
      </:item>
      <:item title="Added On"><%= Calendar.strftime(@user_role.inserted_at, "%d %b %Y, %H:%M") %></:item>
    </.list>

    <.back navigate={~p"/groups/#{@current_group.id}/user_roles"} class="mt-6">Back to user roles</.back>
    """
  end
end
