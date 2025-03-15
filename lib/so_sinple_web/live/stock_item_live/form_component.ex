defmodule SoSinpleWeb.StockItemLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto w-full p-6">
      <div class="mb-8 rounded-lg bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-200 dark:border-zinc-700 p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-full bg-zinc-100 dark:bg-zinc-800">
            <.icon name="hero-building-office" class="size-5 text-zinc-600 dark:text-zinc-400" />
          </div>
          <div>
            <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
              QG : <%= @current_headquarters.name %>
            </h3>
            <p class="text-sm text-zinc-600 dark:text-zinc-400">
              <%= @current_headquarters.address %>
            </p>
          </div>
        </div>
      </div>

      <h1 class="text-2xl text-zinc-800 dark:text-zinc-200 font-bold">
        <%= if @action == :new, do: "Ajouter un produit au stock", else: "Modifier le stock" %>
      </h1>
      <p class="mt-1 text-zinc-600 dark:text-zinc-400">
        <%= if @action == :new do %>
          Ajoutez un nouveau produit à votre inventaire et définissez ses quantités.
        <% else %>
          Mettez à jour les informations de stock du produit.
        <% end %>
      </p>

      <.separator class="my-8" />

      <.form
        for={@form}
        id="stock-item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <section class="mb-10">
          <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Gestion du stock</h2>
          <div class="space-y-6">
            <.select
              field={@form[:item_id]}
              label="Produit"
              sublabel="Requis"
              prompt="Sélectionnez un produit"
              options={for item <- @items, do: {item.name, item.id}}
              help_text="Choisissez le produit à gérer en stock"
              class="pl-9"
            >
              <:inner_prefix>
                <.icon name="hero-cube" class="size-4 text-zinc-500" />
              </:inner_prefix>
            </.select>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <.input
                field={@form[:available_quantity]}
                type="number"
                min="0"
                label="Quantité disponible"
                sublabel="Requis"
                placeholder="0"
                help_text="Nombre d'unités actuellement en stock"
                class="pl-9"
              >
                <:inner_prefix>
                  <.icon name="hero-scale" class="size-4 text-zinc-500" />
                </:inner_prefix>
              </.input>

              <.input
                field={@form[:alert_threshold]}
                type="number"
                min="0"
                label="Seuil d'alerte"
                sublabel="Requis"
                placeholder="10"
                help_text="Quantité minimale avant alerte de réapprovisionnement"
                class="pl-9"
              >
                <:inner_prefix>
                  <.icon name="hero-bell-alert" class="size-4 text-zinc-500" />
                </:inner_prefix>
              </.input>
            </div>

            <.switch
              field={@form[:available]}
              label="Disponible à la vente ?"
              help_text="Désactivez pour masquer temporairement ce produit des ventes"
            />
          </div>
        </section>

        <div class="flex justify-end space-x-4">
          <.button
            type="button"
            variant="ghost"
            phx-click={JS.navigate(@patch)}
          >
            Annuler
          </.button>
          <.button variant="solid" type="submit">
            <%= if @action == :new, do: "Ajouter au stock", else: "Enregistrer les modifications" %>
          </.button>
        </div>
      </.form>
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
         |> put_flash(:info, "Stock mis à jour avec succès")
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
         |> put_flash(:info, "Produit ajouté au stock avec succès")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
