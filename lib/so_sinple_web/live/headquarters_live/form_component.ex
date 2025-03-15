defmodule SoSinpleWeb.HeadquartersLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Organizations

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto w-full p-6">
      <h1 class="text-2xl text-zinc-800 dark:text-zinc-200 font-bold">
        <%= if @action == :new, do: "Ajouter un QG", else: "Modifier le QG" %>
      </h1>
      <p class="mt-1 text-zinc-600 dark:text-zinc-400">
        <%= if @action == :new do %>
          Ajoutez un nouveau QG pour votre groupe.
        <% else %>
          Mettez à jour les informations du QG.
        <% end %>
      </p>

      <.separator class="my-8" />

      <.form
        for={@form}
        id="headquarters-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <section class="mb-10">
          <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Informations générales</h2>
          <div class="space-y-6">
            <.input
              field={@form[:name]}
              type="text"
              label="Nom du QG"
              sublabel="Requis"
              placeholder="Entrez le nom du QG"
              help_text="Choisissez un nom identifiable pour ce QG"
              class="pl-9"
            >
              <:inner_prefix>
                <.icon name="hero-building-office" class="size-4 text-zinc-500" />
              </:inner_prefix>
            </.input>

            <.textarea
              field={@form[:address]}
              label="Adresse"
              sublabel="Requis"
              description="Adresse complète du QG"
              placeholder="Numéro, rue, code postal, ville..."
              rows={3}
            />
          </div>
        </section>

        <section class="mb-10">
          <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Localisation</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <.input
              field={@form[:latitude]}
              type="number"
              step="any"
              label="Latitude"
              sublabel="Requis"
              placeholder="Ex: 48.8566"
              help_text="Coordonnée géographique nord-sud"
              class="pl-9"
            >
              <:inner_prefix>
                <.icon name="hero-map-pin" class="size-4 text-zinc-500" />
              </:inner_prefix>
            </.input>

            <.input
              field={@form[:longitude]}
              type="number"
              step="any"
              label="Longitude"
              sublabel="Requis"
              placeholder="Ex: 2.3522"
              help_text="Coordonnée géographique est-ouest"
              class="pl-9"
            >
              <:inner_prefix>
                <.icon name="hero-map-pin" class="size-4 text-zinc-500" />
              </:inner_prefix>
            </.input>
          </div>
        </section>

        <section class="mb-10">
          <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Contact et statut</h2>
          <div class="space-y-6">
            <.input
              field={@form[:phone]}
              type="tel"
              label="Téléphone"
              sublabel="Requis"
              placeholder="Ex: +33 1 23 45 67 89"
              help_text="Numéro de téléphone principal"
              class="pl-9"
            >
              <:inner_prefix>
                <.icon name="hero-phone" class="size-4 text-zinc-500" />
              </:inner_prefix>
            </.input>

            <.switch
              field={@form[:active]}
              label="Actif ?"
              help_text="Les sièges sociaux actifs sont visibles et peuvent être sélectionnés"
            />
          </div>
        </section>

        <div class="flex justify-end space-x-4">
          <.button
            type="button"
            variant="ghost"
            phx-click={JS.navigate(~p"/headquarters")}
          >
            Annuler
          </.button>
          <.button variant="solid" type="submit">
            <%= if @action == :new, do: "Créer le QG", else: "Enregistrer les modifications" %>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{headquarters: headquarters} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Organizations.change_headquarters(headquarters))
     end)}
  end

  @impl true
  def handle_event("validate", %{"headquarters" => headquarters_params}, socket) do
    changeset = Organizations.change_headquarters(socket.assigns.headquarters, headquarters_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"headquarters" => headquarters_params}, socket) do
    # Ajouter automatiquement le group_id
    headquarters_params = Map.put(headquarters_params, "group_id", socket.assigns.current_group.id)

    save_headquarters(socket, socket.assigns.action, headquarters_params)
  end

  defp save_headquarters(socket, :edit, headquarters_params) do
    case Organizations.update_headquarters(socket.assigns.headquarters, headquarters_params) do
      {:ok, headquarters} ->
        notify_parent({:saved, headquarters})

        {:noreply,
         socket
         |> put_flash(:info, "Headquarters updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_headquarters(socket, :new, headquarters_params) do
    case Organizations.create_headquarters(headquarters_params) do
      {:ok, headquarters} ->
        notify_parent({:saved, headquarters})

        {:noreply,
         socket
         |> put_flash(:info, "Headquarters created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
