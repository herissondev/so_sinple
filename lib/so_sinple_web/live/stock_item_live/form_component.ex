defmodule SoSinpleWeb.StockItemLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="stock-item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.select
          field={@form[:item_id]}
          label="Item"
          prompt="Select an item"
          options={for item <- @items, do: {item.name, item.id}}
        />
        <.input field={@form[:quantity]} type="number" label="Quantity" min="0" />
        <.input field={@form[:available]} type="checkbox" label="Available" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Stock Item</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{stock_item: stock_item} = assigns, socket) do
    # Récupérer les items disponibles pour le groupe
    items = Inventory.list_items_by_group(assigns.current_group.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:items, items)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_stock_item(stock_item))
     end)}
  end

  @impl true
  def handle_event("validate", %{"stock_item" => stock_item_params}, socket) do
    changeset = Inventory.change_stock_item(socket.assigns.stock_item, stock_item_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"stock_item" => stock_item_params}, socket) do
    # Convertir les IDs en entiers
    stock_item_params = stock_item_params
    |> Map.put("item_id", String.to_integer(stock_item_params["item_id"] || "0"))
    |> Map.put("headquarters_id", socket.assigns.current_headquarters.id)

    save_stock_item(socket, socket.assigns.action, stock_item_params)
  end

  defp save_stock_item(socket, :edit, stock_item_params) do
    case Inventory.update_stock_item(socket.assigns.stock_item, stock_item_params) do
      {:ok, stock_item} ->
        notify_parent({:saved, stock_item})

        {:noreply,
         socket
         |> put_flash(:info, "Stock item updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_stock_item(socket, :new, stock_item_params) do
    case Inventory.create_stock_item(stock_item_params) do
      {:ok, stock_item} ->
        notify_parent({:saved, stock_item})

        {:noreply,
         socket
         |> put_flash(:info, "Stock item created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
