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
       |> put_flash(:error, "Seul l'administrateur du groupe peut ajouter des membres")
       |> redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/user_roles")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    user_role = %UserRole{group_id: socket.assigns.current_group.id}

    {:noreply,
     socket
     |> assign(:page_title, "Nouveau membre")
     |> assign(:user_role, user_role)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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

      <.back navigate={~p"/groups/#{@current_group.id}/user_roles"} class="mt-6">Retour aux membres</.back>
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.UserRoleLive.FormComponent, {:saved, _user_role}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Membre ajouté avec succès")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.current_group.id}/user_roles")}
  end
end
