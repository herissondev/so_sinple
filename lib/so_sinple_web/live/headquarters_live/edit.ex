defmodule SoSinpleWeb.HeadquartersLive.Edit do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Headquarters

  @impl true
  def mount(%{"headquarter_id" => id}, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"headquarter_id" => id}, _url, socket) do
    headquarters = Organizations.get_headquarters!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Edit Headquarters - #{headquarters.name}")
     |> assign(:headquarters, headquarters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SoSinpleWeb.HeadquartersLive.FormComponent}
        id={@headquarters.id}
        title={@page_title}
        action={:edit}
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
     |> put_flash(:info, "Headquarters updated successfully")
     |> push_navigate(to: ~p"/groups/#{@current_group.id}/headquarters")}
  end
end
