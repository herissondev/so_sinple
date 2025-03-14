defmodule SoSinpleWeb.OrderItemLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Orders

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage order_item records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="order_item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:quantite]} type="number" label="Quantite" />
        <.input field={@form[:prix_unitaire]} type="number" label="Prix unitaire" step="any" />
        <.input field={@form[:notes_speciales]} type="text" label="Notes speciales" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Order item</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{order_item: order_item} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Orders.change_order_item(order_item))
     end)}
  end

  @impl true
  def handle_event("validate", %{"order_item" => order_item_params}, socket) do
    changeset = Orders.change_order_item(socket.assigns.order_item, order_item_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"order_item" => order_item_params}, socket) do
    save_order_item(socket, socket.assigns.action, order_item_params)
  end

  defp save_order_item(socket, :edit, order_item_params) do
    case Orders.update_order_item(socket.assigns.order_item, order_item_params) do
      {:ok, order_item} ->
        notify_parent({:saved, order_item})

        {:noreply,
         socket
         |> put_flash(:info, "Order item updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_order_item(socket, :new, order_item_params) do
    case Orders.create_order_item(order_item_params) do
      {:ok, order_item} ->
        notify_parent({:saved, order_item})

        {:noreply,
         socket
         |> put_flash(:info, "Order item created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
