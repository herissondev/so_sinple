defmodule SoSinpleWeb.ItemLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @is_admin do %>
        <.simple_form
          for={@form}
          id="item-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:price]} type="number" label="Price" step="0.01" min="0" />
          <.input field={@form[:image_url]} type="text" label="Image URL" />
          <.input field={@form[:available]} type="checkbox" label="Available" />

          <:actions>
            <.button phx-disable-with="Saving...">Save Item</.button>
          </:actions>
        </.simple_form>
      <% else %>
        <div class="alert alert-warning">
          <p>You do not have permission to edit items for this group. Only the group administrator can manage items.</p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_item(item))
     end)}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset = Inventory.change_item(socket.assigns.item, item_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    # Ajouter le group_id si c'est un nouvel item
    item_params = if socket.assigns.action == :new do
      Map.put(item_params, "group_id", socket.assigns.current_group.id)
    else
      item_params
    end

    save_item(socket, socket.assigns.action, item_params)
  end

  defp save_item(socket, :edit, item_params) do
    case Inventory.update_item(socket.assigns.item, item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_item(socket, :new, item_params) do
    case Inventory.create_item(item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
