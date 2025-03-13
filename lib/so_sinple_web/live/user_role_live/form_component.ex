defmodule SoSinpleWeb.UserRoleLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Organizations
  alias SoSinple.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>User role for <%= @current_group.name %></:subtitle>
      </.header>

      <%= if @can_manage_roles do %>
        <.simple_form
          for={@form}
          id="user_role-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            field={@form[:user_id]}
            type="select"
            label="User"
            prompt="Select a user"
            options={@user_options}
          />
          <.input
            field={@form[:role]}
            type="select"
            label="Role"
            prompt="Select a role"
            options={@role_options}
          />
          <div class="headquarters-field" data-show-if={@show_headquarters_field}>
            <.input
              field={@form[:headquarters_id]}
              type="select"
              label="Headquarters"
              prompt="Select a headquarters"
              options={@headquarters_options}
            />
          </div>
          <.input field={@form[:active]} type="checkbox" label="Active" />

          <:actions>
            <.button phx-disable-with="Saving...">Save User Role</.button>
          </:actions>
        </.simple_form>

        <script>
          // Script pour afficher/masquer le champ headquarters en fonction du rôle sélectionné
          document.addEventListener('DOMContentLoaded', function() {
            const roleSelect = document.querySelector('select[name="user_role[role]"]');
            const headquartersField = document.querySelector('.headquarters-field');

            function updateHeadquartersVisibility() {
              const role = roleSelect.value;
              if (role === 'responsable_qg' || role === 'livreur') {
                headquartersField.style.display = 'block';
              } else {
                headquartersField.style.display = 'none';
              }
            }

            if (roleSelect && headquartersField) {
              roleSelect.addEventListener('change', updateHeadquartersVisibility);
              updateHeadquartersVisibility();
            }
          });
        </script>
      <% else %>
        <div class="alert alert-warning">
          <p>You do not have permission to edit user roles for this group. Only the group administrator can manage user roles.</p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{user_role: user_role} = assigns, socket) do
    user_options = get_user_options()
    role_options = get_role_options()
    headquarters_options = get_headquarters_options(assigns.current_group.id)

    # Déterminer si le champ headquarters doit être affiché
    show_headquarters_field = user_role.role in ["responsable_qg", "livreur"]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user_options, user_options)
     |> assign(:role_options, role_options)
     |> assign(:headquarters_options, headquarters_options)
     |> assign(:show_headquarters_field, show_headquarters_field)
     |> assign_new(:form, fn ->
       to_form(Organizations.change_user_role(user_role))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user_role" => user_role_params}, socket) do
    changeset = Organizations.change_user_role(socket.assigns.user_role, user_role_params)

    # Mettre à jour la visibilité du champ headquarters
    show_headquarters_field = user_role_params["role"] in ["responsable_qg", "livreur"]

    {:noreply,
     socket
     |> assign(:show_headquarters_field, show_headquarters_field)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user_role" => user_role_params}, socket) do
    # Convertir les IDs en entiers
    user_role_params = user_role_params
    |> Map.put("user_id", String.to_integer(user_role_params["user_id"] || "0"))
    |> Map.put("group_id", socket.assigns.current_group.id)

    # Gérer le headquarters_id en fonction du rôle
    user_role_params = if user_role_params["role"] in ["responsable_qg", "livreur"] do
      Map.put(user_role_params, "headquarters_id", String.to_integer(user_role_params["headquarters_id"] || "0"))
    else
      Map.put(user_role_params, "headquarters_id", nil)
    end

    save_user_role(socket, socket.assigns.action, user_role_params)
  end

  defp save_user_role(socket, :edit, user_role_params) do
    case Organizations.update_user_role(socket.assigns.user_role, user_role_params) do
      {:ok, user_role} ->
        notify_parent({:saved, user_role})

        {:noreply,
         socket
         |> put_flash(:info, "User role updated successfully")
         |> push_patch(to: socket.assigns.patch)}

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
         |> put_flash(:info, "User role created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # Récupérer la liste des utilisateurs pour le select
  defp get_user_options do
    Accounts.list_users()
    |> Enum.map(fn user -> {user.email, user.id} end)
  end

  # Récupérer la liste des QG pour le select, filtrés par groupe
  defp get_headquarters_options(group_id) do
    Organizations.list_active_headquarters_by_group(group_id)
    |> Enum.map(fn hq -> {hq.name, hq.id} end)
  end

  # Récupérer la liste des rôles disponibles
  defp get_role_options do
    SoSinple.Organizations.UserRole.roles()
    |> Enum.map(fn role -> {String.capitalize(String.replace(role, "_", " ")), role} end)
  end
end
