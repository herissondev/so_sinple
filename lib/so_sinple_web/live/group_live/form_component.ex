defmodule SoSinpleWeb.GroupLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Organizations

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto w-full p-6">
      <h1 class="text-2xl text-zinc-800 dark:text-zinc-200 font-bold">
        <%= if @action == :new, do: "Créer un nouveau groupe", else: "Modifier le groupe" %>
      </h1>
      <p class="mt-1 text-zinc-600 dark:text-zinc-400">
        <%= if @action == :new do %>
          Créer un nouveau groupe pour gérer vos SOS.
        <% else %>
          Mettez à jour les informations et les paramètres de votre groupe.
        <% end %>
      </p>

      <.separator class="my-8" />

      <.form
        for={@form}
        id="group-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <section class="mb-10">
          <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Informations du groupe</h2>
          <div class="space-y-6">
            <.input
              field={@form[:name]}
              type="text"
              label="Nom du groupe"
              sublabel="Requis"
              placeholder="Entrez le nom du groupe"
              help_text="Choisissez un nom clair et descriptif pour votre groupe"
              class="pl-9"
            >
              <:inner_prefix>
                <.icon name="hero-user-group" class="size-4 text-zinc-500" />
              </:inner_prefix>
            </.input>

            <.textarea
              field={@form[:description]}
              label="Description"
              sublabel="Optionnel"
              description="Fournissez des détails sur le but et les activités du groupe"
              placeholder="Décrivez le but et les objectifs de ce groupe..."
              rows={4}
            />

            <.switch
              field={@form[:active]}
              label="Actif ?"
              help_text="Les groupes actifs sont visibles pour les membres et peuvent participer aux activités"
            />
          </div>
        </section>

        <div class="flex justify-end space-x-4">
          <.button
            type="button"
            variant="ghost"
            phx-click={JS.navigate(~p"/groups")}
          >
            Annuler
          </.button>
          <.button variant="solid" type="submit">
            <%= if @action == :new, do: "Créer le groupe", else: "Enregistrer les modifications" %>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{group: group} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Organizations.change_group(group))
     end)}
  end

  @impl true
  def handle_event("validate", %{"group" => group_params}, socket) do
    changeset = Organizations.change_group(socket.assigns.group, group_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"group" => group_params}, socket) do
    # Add the admin_id if it's a new group
    group_params = if socket.assigns.action == :new do
      Map.put(group_params, "admin_id", socket.assigns.current_user.id)
    else
      group_params
    end

    save_group(socket, socket.assigns.action, group_params)
  end

  defp save_group(socket, :edit, group_params) do
    case Organizations.update_group(socket.assigns.group, group_params) do
      {:ok, group} ->
        notify_parent({:saved, group})

        {:noreply,
         socket
         |> put_flash(:info, "Group updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_group(socket, :new, group_params) do
    case Organizations.create_group(group_params) do
      {:ok, group} ->
        notify_parent({:saved, group})

        {:noreply,
         socket
         |> put_flash(:info, "Group created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
