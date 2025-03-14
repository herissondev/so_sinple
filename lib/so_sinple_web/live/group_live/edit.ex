defmodule SoSinpleWeb.GroupLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations

  @impl true
  def mount(%{"group_id" => id}, _session, socket) do
    group = Organizations.get_group!(id)

    # Check if the current user is the admin of the group
    if group.admin_id == socket.assigns.current_user.id do
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You can only edit groups you administer")
       |> redirect(to: ~p"/groups")}
    end
  end

  @impl true
  def handle_params(%{"group_id" => id}, _url, socket) do
    group = Organizations.get_group!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Edit Group - #{group.name}")
     |> assign(:group, group)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Edit Group
        <:subtitle>Update your group settings</:subtitle>
      </.header>

      <.live_component
        module={SoSinpleWeb.GroupLive.FormComponent}
        id={@group.id}
        title={@page_title}
        action={:edit}
        group={@group}
        current_user={@current_user}
        patch={~p"/groups"}
      />

      <.back navigate={~p"/groups"} class="mt-6">Back to groups</.back>
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.GroupLive.FormComponent, {:saved, _group}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Group updated successfully")
     |> push_navigate(to: ~p"/groups")}
  end
end
