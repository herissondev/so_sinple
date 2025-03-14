defmodule SoSinpleWeb.UserRoleLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations

  @impl true
  def mount(%{"user_role_id" => id}, _session, socket) do
    user_role = Organizations.get_user_role!(id)

    # Check if the current user is the admin of the group
    if socket.assigns.current_group.admin_id == socket.assigns.current_user.id do
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Only the group administrator can edit user roles")
       |> redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/user_roles")}
    end
  end

  @impl true
  def handle_params(%{"user_role_id" => id}, _url, socket) do
    user_role = Organizations.get_user_role!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Edit User Role")
     |> assign(:user_role, user_role)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Edit User Role
        <:subtitle>Update member role in <%= @current_group.name %></:subtitle>
      </.header>

      <.live_component
        module={SoSinpleWeb.UserRoleLive.FormComponent}
        id={@user_role.id}
        title={@page_title}
        action={:edit}
        user_role={@user_role}
        current_user={@current_user}
        current_group={@current_group}
        patch={~p"/groups/#{@current_group.id}/user_roles"}
      />

      <.back navigate={~p"/groups/#{@current_group.id}/user_roles"} class="mt-6">Back to user roles</.back>
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.UserRoleLive.FormComponent, {:saved, _user_role}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User role updated successfully")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.current_group.id}/user_roles")}
  end
end
