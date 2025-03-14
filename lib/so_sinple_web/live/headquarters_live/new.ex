defmodule SoSinpleWeb.HeadquartersLive.New do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Headquarters

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    headquarters = %Headquarters{group_id: socket.assigns.current_group.id}

    {:noreply,
     socket
     |> assign(:page_title, "New Headquarters for #{socket.assigns.current_group.name}")
     |> assign(:headquarters, headquarters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SoSinpleWeb.HeadquartersLive.FormComponent}
        id={:new}
        title={@page_title}
        action={:new}
        headquarters={@headquarters}
        current_group={@current_group}
        patch={~p"/groups/#{@current_group.id}/headquarters"}
      />

      <.back navigate={~p"/groups/#{@current_group.id}/headquarters"} class="mt-6">Back to headquarters</.back>
    </div>
    """
  end

  @impl true
  def handle_info({SoSinpleWeb.HeadquartersLive.FormComponent, {:saved, _headquarters}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Headquarters created successfully")
     |> push_navigate(to: ~p"/groups/#{@current_group.id}/headquarters")}
  end
end
