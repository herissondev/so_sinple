defmodule SoSinpleWeb.HeadquartersLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Organizations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Headquarters for <%= @current_group.name %></:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="headquarters-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:address]} type="textarea" label="Address" />
        <.input field={@form[:latitude]} type="number" label="Latitude" step="any" />
        <.input field={@form[:longitude]} type="number" label="Longitude" step="any" />
        <.input field={@form[:phone]} type="text" label="Phone" />
        <.input field={@form[:active]} type="checkbox" label="Active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Headquarters</.button>
        </:actions>
      </.simple_form>
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
         |> push_patch(to: socket.assigns.patch)}

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
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
