defmodule SoSinpleWeb.ItemLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto w-full p-6">
      <%= if @is_admin do %>
        <h1 class="text-2xl text-zinc-800 dark:text-zinc-200 font-bold">
          <%= if @action == :new, do: "Ajouter un produit", else: "Modifier le produit" %>
        </h1>
        <p class="mt-1 text-zinc-600 dark:text-zinc-400">
          <%= if @action == :new do %>
            Ajoutez un nouveau produit à votre catalogue.
          <% else %>
            Mettez à jour les informations du produit.
          <% end %>
        </p>

        <.separator class="my-8" />

        <.form
          for={@form}
          id="item-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <section class="mb-10">
            <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Informations du produit</h2>
            <div class="space-y-6">
              <.input
                field={@form[:name]}
                type="text"
                label="Nom du produit"
                sublabel="Requis"
                placeholder="Ex: Couscous Royal"
                help_text="Nom du plat ou du produit"
                class="pl-9"
              >
                <:inner_prefix>
                  <.icon name="hero-cake" class="size-4 text-zinc-500" />
                </:inner_prefix>
              </.input>

              <.textarea
                field={@form[:description]}
                label="Description"
                sublabel="Requis"
                description="Décrivez le produit en détail"
                placeholder="Décrivez les ingrédients, la préparation, les allergènes éventuels..."
                rows={4}
              />

              <.input
                field={@form[:price]}
                type="number"
                step="0.01"
                min="0"
                label="Prix"
                sublabel="Requis"
                placeholder="0.00"
                help_text="Prix en euros"
                class="pl-9"
              >
                <:inner_prefix>
                  <.icon name="hero-currency-euro" class="size-4 text-zinc-500" />
                </:inner_prefix>
              </.input>
            </div>
          </section>

          <section class="mb-10">
            <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Image et disponibilité</h2>
            <div class="space-y-6">
              <.input
                field={@form[:image_url]}
                type="text"
                label="URL de l'image"
                sublabel="Requis"
                placeholder="https://exemple.com/image.jpg"
                help_text="Lien vers une image représentative du produit"
                class="pl-9"
              >
                <:inner_prefix>
                  <.icon name="hero-photo" class="size-4 text-zinc-500" />
                </:inner_prefix>
              </.input>

              <.switch
                field={@form[:available]}
                label="Disponible ?"
                help_text="Activez pour rendre le produit disponible à la vente"
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
              <%= if @action == :new, do: "Créer le produit", else: "Enregistrer les modifications" %>
            </.button>
          </div>
        </.form>
      <% else %>
        <div class="rounded-lg bg-amber-50 dark:bg-amber-950 p-4 border border-amber-200 dark:border-amber-900">
          <div class="flex items-center gap-3">
            <.icon name="hero-exclamation-triangle" class="size-5 text-amber-600 dark:text-amber-500" />
            <h3 class="text-sm font-medium text-amber-800 dark:text-amber-200">Accès restreint</h3>
          </div>
          <p class="mt-2 text-sm text-amber-700 dark:text-amber-300">
            Vous n'avez pas les permissions nécessaires pour modifier les produits de ce groupe. Seul l'administrateur du groupe peut gérer les produits.
          </p>
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
