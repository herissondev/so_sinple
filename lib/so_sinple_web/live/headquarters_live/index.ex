defmodule SoSinpleWeb.HeadquartersLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Headquarters

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    # Le groupe est déjà assigné par le hook check_group_access
    headquarters_list = Organizations.list_headquarters_by_group(group_id)
    {:ok, assign(socket, :headquarters_list, headquarters_list)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    headquarters_list = Organizations.list_headquarters_by_group(socket.assigns.current_group.id)
    socket
    |> assign(:page_title, "Headquarters for #{socket.assigns.current_group.name}")
    |> assign(:headquarters_list, headquarters_list)
  end

  @impl true
  def handle_info({SoSinpleWeb.HeadquartersLive.FormComponent, {:saved, _headquarters}}, socket) do
    headquarters_list = Organizations.list_headquarters_by_group(socket.assigns.current_group.id)
    {:noreply, assign(socket, :headquarters_list, headquarters_list)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    headquarters = Organizations.get_headquarters!(id)

    # Vérifier si l'utilisateur est l'administrateur du groupe
    if socket.assigns.current_group.admin_id == socket.assigns.current_user.id do
      {:ok, _} = Organizations.delete_headquarters(headquarters)
      headquarters_list = Organizations.list_headquarters_by_group(socket.assigns.current_group.id)
      {:noreply, assign(socket, :headquarters_list, headquarters_list)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Only the group administrator can delete headquarters.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Headquarters for <%= @current_group.name %>
      <:actions>
        <.link navigate={~p"/groups/#{@current_group.id}/headquarters/new"}>
          <.button>New Headquarters</.button>
        </.link>
      </:actions>
    </.header>

    <.table>
      <.table_head>
        <:col>Name</:col>
        <:col>Address</:col>
        <:col>Phone</:col>
        <:col>Status</:col>
        <:col></:col>
      </.table_head>
      <.table_body>
        <.table_row :for={hq <- @headquarters_list}>
          <:cell class="w-full flex items-center gap-2">
            <div class="flex flex-col gap-0.5">
              <span class="font-semibold"><%= hq.name %></span>
            </div>
          </:cell>
          <:cell>
            <span class="text-zinc-400 text-sm/3"><%= hq.address %></span>
          </:cell>
          <:cell><%= hq.phone %></:cell>
          <:cell>
            <%= if hq.active do %>
              <.badge color="green">Active</.badge>
            <% else %>
              <.badge color="red">Inactive</.badge>
            <% end %>
          </:cell>
          <:cell>
            <.dropdown>
              <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                <.icon name="hero-ellipsis-horizontal" class="size-5" />
              </:toggle>
              <.dropdown_link navigate={~p"/groups/#{@current_group.id}/headquarters/#{hq.id}"}>
                View
              </.dropdown_link>
              <.dropdown_link navigate={~p"/groups/#{@current_group.id}/headquarters/#{hq.id}/edit"}>
                Edit
              </.dropdown_link>
              <%= if @current_group.admin_id == @current_user.id do %>
                <.dropdown_link
                  phx-click={JS.push("delete", value: %{id: hq.id})}
                  data-confirm="Are you sure?">
                  Delete
                </.dropdown_link>
              <% end %>
            </.dropdown>
          </:cell>
        </.table_row>
      </.table_body>
    </.table>

    <.back navigate={~p"/groups/#{@current_group.id}"} class="mt-6">Back to group</.back>
    """
  end
end
