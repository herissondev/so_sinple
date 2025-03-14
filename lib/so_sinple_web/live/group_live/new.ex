defmodule SoSinpleWeb.GroupLive.New do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Group

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    group = %Group{}

    {:noreply,
     socket
     |> assign(:page_title, "New Group")
     |> assign(:group, group)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        New Group
        <:subtitle>Create a new group to manage your items and headquarters</:subtitle>
      </.header>

      <.live_component
        module={SoSinpleWeb.GroupLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
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
     |> put_flash(:info, "Group created successfully")
     |> push_navigate(to: ~p"/groups")}
  end
end
