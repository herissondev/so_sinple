defmodule SoSinpleWeb.GroupLive.Index do
  use SoSinpleWeb, :live_view

  alias SoSinple.Organizations
  alias SoSinple.Organizations.Group

  @impl true
  def mount(_params, _session, socket) do
    groups = Organizations.list_user_groups(socket.assigns.current_user.id)
    {:ok, assign(socket, :groups, groups)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Group")
    |> assign(:group, Organizations.get_group!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Group")
    |> assign(:group, %Group{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Groups")
    |> assign(:group, nil)
  end

  @impl true
  def handle_info({SoSinpleWeb.GroupLive.FormComponent, {:saved, _group}}, socket) do
    groups = Organizations.list_user_groups(socket.assigns.current_user.id)
    {:noreply, assign(socket, :groups, groups)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    group = Organizations.get_group!(id)

    if group.admin_id == socket.assigns.current_user.id do
      {:ok, _} = Organizations.delete_group(group)

      {:noreply,
       socket
       |> put_flash(:info, "Group deleted successfully")
       |> assign(:groups, Organizations.list_user_groups(socket.assigns.current_user.id))}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You can only delete groups you administer")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      My Groups
      <:subtitle>Manage your groups and their resources</:subtitle>
      <:actions>
        <.link navigate={~p"/groups/new"}>
          <.button>New Group</.button>
        </.link>
      </:actions>
    </.header>

    <.table>
      <.table_head>
        <:col>Group</:col>
        <:col>Description</:col>
        <:col>Role</:col>
        <:col></:col>
      </.table_head>
      <.table_body>
        <.table_row :for={group <- @groups}>
          <:cell>
            <div class="font-semibold"><%= group.name %></div>
          </:cell>
          <:cell>
            <span class="text-zinc-400 text-sm/3"><%= group.description %></span>
          </:cell>
          <:cell>
            <%= if group.admin_id == @current_user.id do %>
              <.badge color="green">Admin</.badge>
            <% else %>
              <.badge color="blue">Member</.badge>
            <% end %>
          </:cell>
          <:cell>
            <.dropdown>
              <:toggle class="size-6 cursor-pointer rounded-md flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800">
                <.icon name="hero-ellipsis-horizontal" class="size-5" />
              </:toggle>
              <.dropdown_link navigate={~p"/groups/#{group.id}"}>
                View
              </.dropdown_link>
              <%= if group.admin_id == @current_user.id do %>
                <.dropdown_link navigate={~p"/groups/#{group.id}/edit"}>
                  Edit
                </.dropdown_link>
                <.dropdown_link
                  phx-click={JS.push("delete", value: %{id: group.id})}
                  data-confirm="Are you sure you want to delete this group?">
                  Delete
                </.dropdown_link>
              <% end %>
            </.dropdown>
          </:cell>
        </.table_row>
      </.table_body>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="group-modal" show on_cancel={JS.patch(~p"/groups")}>
      <.live_component
        module={SoSinpleWeb.GroupLive.FormComponent}
        id={@group.id || :new}
        title={@page_title}
        action={@live_action}
        group={@group}
        current_user={@current_user}
        patch={~p"/groups"}
      />
    </.modal>
    """
  end
end
