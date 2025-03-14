defmodule SoSinpleWeb.UserRoleLive.New do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.UserRole

  @impl true
  def mount(_params, _session, socket) do
    # Check if the current user is the admin of the group
    if socket.assigns.current_group.admin_id == socket.assigns.current_user.id do
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Only the group administrator can add user roles")
       |> redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/user_roles")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    user_role = %UserRole{group_id: socket.assigns.current_group.id}

    {:noreply,
     socket
     |> assign(:page_title, "New User Role")
     |> assign(:user_role, user_role)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        New User Role
        <:subtitle>Add a new member to <%= @current_group.name %></:subtitle>
      </.header>

      <.live_component
        module={SoSinpleWeb.UserRoleLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
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
     |> put_flash(:info, "User role created successfully")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.current_group.id}/user_roles")}
  end
end
