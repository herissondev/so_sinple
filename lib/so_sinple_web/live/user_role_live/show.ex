defmodule SoSinpleWeb.UserRoleLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations

  @impl true
  def mount(_params, _session, socket) do
    # Le groupe et le rôle utilisateur sont déjà assignés par le hook check_user_role_access
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"group_id" => _group_id, "user_role_id" => user_role_id}, _, socket) do
    # Précharger les associations
    user_role = Organizations.get_user_role_with_associations!(user_role_id)

    {:noreply,
     socket
     |> assign(:page_title, "User Role Details")
     |> assign(:user_role, user_role)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      User Role Details
      <:subtitle>Role information for <%= @current_group.name %></:subtitle>
      <:actions>
        <%= if @can_manage_roles do %>
          <.link patch={~p"/groups/#{@current_group.id}/user_roles/#{@user_role.id}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit user role</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="User">
        <%= if @user_role.user, do: @user_role.user.email, else: "Unknown" %>
      </:item>
      <:item title="Role"><%= @user_role.role %></:item>
      <:item title="Group"><%= @current_group.name %></:item>
      <:item title="Headquarters">
        <%= if @user_role.headquarters, do: @user_role.headquarters.name, else: "N/A" %>
      </:item>
      <:item title="Active"><%= @user_role.active %></:item>
    </.list>

    <.back navigate={~p"/groups/#{@current_group.id}/user_roles"} class="mt-10">Back to user roles</.back>

    <.modal :if={@live_action == :edit} id="user_role-modal" show on_cancel={JS.patch(~p"/groups/#{@current_group.id}/user_roles/#{@user_role.id}")}>
      <.live_component
        module={SoSinpleWeb.UserRoleLive.FormComponent}
        id={@user_role.id}
        title={@page_title}
        action={@live_action}
        user_role={@user_role}
        current_group={@current_group}
        current_user={@current_user}
        can_manage_roles={@can_manage_roles}
        patch={~p"/groups/#{@current_group.id}/user_roles/#{@user_role.id}"}
      />
    </.modal>
    """
  end
end
