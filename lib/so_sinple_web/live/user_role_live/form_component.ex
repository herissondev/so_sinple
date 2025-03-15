defmodule SoSinpleWeb.UserRoleLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Organizations
  alias SoSinple.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto w-full p-6">
      <h1 class="text-2xl text-zinc-800 dark:text-zinc-200 font-bold">
        <%= if @action == :new, do: "Ajouter un membre", else: "Modifier le rôle du membre" %>
      </h1>
      <p class="mt-1 text-zinc-600 dark:text-zinc-400">
        <%= if @action == :new do %>
          Ajoutez un nouveau membre à votre équipe et définissez son rôle.
        <% else %>
          Mettez à jour le rôle et les permissions du membre.
        <% end %>
      </p>

      <.separator class="my-8" />

      <.form
        for={@form}
        id="user-role-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <section class="mb-10">
          <h2 class="text-lg font-semibold text-zinc-700 dark:text-zinc-300 mb-4">Informations du membre</h2>
          <div class="space-y-6">
            <.autocomplete
              field={@form[:user_id]}
              type="select"
              label="Utilisateur"
              sublabel="Requis"
              prompt="Sélectionnez un utilisateur"
              options={for user <- @users, do: {user.email, user.id}}
              help_text="Choisissez l'utilisateur à ajouter à l'équipe"
            >
              <:option :let={{label, value}}>
                <div class="flex items-center gap-3 p-2 rounded-lg [[data-highlighted]_&]:bg-zinc-100 [[data-selected]_&]:bg-blue-100">
                  <.icon name="hero-user" class="size-4 text-zinc-500" />
                  <div class="font-medium text-sm">{label}</div>
                </div>
              </:option>
            </.autocomplete>

            <.autocomplete
              field={@form[:headquarters_id]}
              type="select"
              label="QG de rattachement"
              sublabel="Requis"
              prompt="Sélectionnez un QG"
              options={for headquarters <- @current_group.headquarters, do: {headquarters.name, headquarters.id}}
              help_text="QG auquel le membre sera rattaché"
            >
              <:option :let={{label, value}}>
                <div class="flex items-center gap-3 p-2 rounded-lg [[data-highlighted]_&]:bg-zinc-100 [[data-selected]_&]:bg-blue-100">
                  <.icon name="hero-building-office" class="size-4 text-zinc-500" />
                  <div class="font-medium text-sm">{label}</div>
                </div>
              </:option>
            </.autocomplete>

            <.select
              field={@form[:role]}
              label="Rôle"
              sublabel="Requis"
              prompt="Sélectionnez un rôle"
              options={role_options()}
              help_text="Définit les permissions et responsabilités du membre"
            >
              <:option :let={{label, value}}>
                <div class="flex items-center gap-3 p-2 rounded-lg [[data-highlighted]_&]:bg-zinc-100 [[data-selected]_&]:bg-blue-100">
                  <.icon name="hero-finger-print" class="size-4 text-zinc-500" />
                  <div class="font-medium text-sm">{label}</div>
                </div>
              </:option>
            </.select>

            <.switch
              field={@form[:active]}
              label="Compte actif ?"
              help_text="Les membres inactifs ne peuvent pas accéder aux fonctionnalités"
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
            <%= if @action == :new, do: "Ajouter le membre", else: "Enregistrer les modifications" %>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{user_role: user_role} = assigns, socket) do
    users = Accounts.list_users()
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:users, users)
     |> assign_new(:form, fn ->
       to_form(Organizations.change_user_role(user_role))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user_role" => user_role_params}, socket) do
    changeset = Organizations.change_user_role(socket.assigns.user_role, user_role_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user_role" => user_role_params}, socket) do
    user_role_params = user_role_params
    |> Map.put("user_id", String.to_integer(user_role_params["user_id"] || "0"))
    |> Map.put("group_id", socket.assigns.current_group.id)

    save_user_role(socket, socket.assigns.action, user_role_params)
  end

  defp save_user_role(socket, :edit, user_role_params) do
    case Organizations.update_user_role(socket.assigns.user_role, user_role_params) do
      {:ok, user_role} ->
        notify_parent({:saved, user_role})

        {:noreply,
         socket
         |> put_flash(:info, "Rôle mis à jour avec succès")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user_role(socket, :new, user_role_params) do
    case Organizations.create_user_role(user_role_params) do
      {:ok, user_role} ->
        notify_parent({:saved, user_role})

        {:noreply,
         socket
         |> put_flash(:info, "Membre ajouté avec succès")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp role_options do
    [
      {"Administrateur du groupe", "admin_groupe"},
      {"Responsable QG", "responsable_qg"},
      {"Livreur", "livreur"}
    ]
  end
end
