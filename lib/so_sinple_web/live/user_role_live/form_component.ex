defmodule SoSinpleWeb.UserRoleLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Organizations
  alias SoSinple.Accounts



  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="user-role-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.autocomplete
          field={@form[:user_id]}
          type="select"
          label="User"
          prompt="Select a user"
          options={for user <- @users, do: {user.email, user.id}}
        />
        <.select
          field={@form[:role]}
          label="Role"
          prompt="Select a role"
          options={role_options()}
        />
        <.input field={@form[:active]} type="checkbox" label="Active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Role</.button>
        </:actions>
      </.simple_form>
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
         |> put_flash(:info, "User role updated successfully")
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
         |> put_flash(:info, "User role created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp role_options do
    [
      {"Admin", "admin_groupe"},
      {"Responsable QG", "responsable_qg"},
      {"Livreur", "livreur"}
    ]
  end
end
