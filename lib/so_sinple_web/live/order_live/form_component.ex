defmodule SoSinpleWeb.OrderLive.FormComponent do
  use SoSinpleWeb, :live_component

  alias SoSinple.Orders
  alias SoSinple.Inventory
  alias SoSinple.Accounts
  alias SoSinple.Organizations

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:order_items, %{})  # Changed to map for easier item quantity tracking
     |> assign(:available_items, [])
     |> assign(:total, 0.0)
     |> assign(:address_suggestions, [])
     |> assign(:address_data, %{})
     |> assign(:finding_optimal_headquarters, false)
     |> assign(:needs_headquarters_update, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Remplissez les informations de la commande</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="order-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h3 class="text-lg font-semibold mb-4">Informations client</h3>
            <.input field={@form[:client_nom]} type="text" label="Nom" required />
            <.input field={@form[:client_prenom]} type="text" label="Prénom" required />
            <.input field={@form[:client_telephone]} type="tel" label="Téléphone" required />
          </div>

          <div>
            <h3 class="text-lg font-semibold mb-4">Informations livraison</h3>
            <div class="relative">
              <%= if @action == :edit do %>
                <.select field={@form[:headquarters_id]} label="Point de vente" options={headquarters_options(@current_group.id)} required />
              <% else %>
                <div class="mb-4">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Point de vente
                  </label>
                  <p class="text-sm text-blue-600 italic">
                    <%= if Map.get(@form.data, :headquarters_id) do %>
                      QG sélectionné: <%= get_headquarters_name(Map.get(@form.data, :headquarters_id)) %>
                    <% else %>
                      Le QG optimal sera automatiquement sélectionné lors de la création de la commande
                    <% end %>
                  </p>
                  <.input field={@form[:headquarters_id]} type="hidden" />
                </div>
              <% end %>
            </div>

            <div class="relative">
              <.autocomplete
                field={@form[:adresse_livraison]}
                label="Adresse de livraison"
                options={@address_suggestions}
                selected={Phoenix.HTML.Form.input_value(@form, :adresse_livraison)}
                on_search="search_address"
                on_select="select_address"
                search_placeholder="Commencez à taper une adresse..."
                no_results_message="Aucune adresse trouvée"
                phx-target={@myself}
                required
              />
            </div>

            <.input field={@form[:date_livraison_prevue]} type="datetime-local" label="Date de livraison prévue" />
            <.select field={@form[:status]} type="select" label="Statut" options={status_options()} required />

            <div class="hidden">
              <.input field={@form[:latitude_livraison]} type="number" step="any" />
              <.input field={@form[:longitude_livraison]} type="number" step="any" />
            </div>
          </div>
        </div>

        <div class="mt-8">
          <h3 class="text-lg font-semibold mb-4">Articles disponibles</h3>

          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            <div :for={item <- @available_items} class="bg-white rounded-lg shadow p-4 border">
              <div class="aspect-w-1 aspect-h-1 w-full overflow-hidden rounded-lg bg-gray-200 mb-4">
                <%= if item.image_url && item.image_url != "" do %>
                  <img src={item.image_url} alt={item.name} class="h-full w-full object-cover object-center" />
                <% else %>
                  <div class="flex items-center justify-center h-full bg-gray-100">
                    <.icon name="hero-photo" class="h-12 w-12 text-gray-300" />
                  </div>
                <% end %>
              </div>
              <h4 class="font-medium text-gray-900"><%= item.name %></h4>
              <p class="text-sm text-gray-500 mb-2"><%= item.description %></p>
              <p class="text-lg font-semibold text-gray-900 mb-3">
                <%= Number.Currency.number_to_currency(item.price) %>
              </p>

              <div class="flex items-center justify-between mt-2">
                <div class="flex items-center space-x-2">
                  <button
                    type="button"
                    phx-click="decrease_quantity"
                    phx-value-id={item.id}
                    phx-target={@myself}
                    class="rounded-full bg-gray-100 p-1 hover:bg-gray-200"
                    disabled={Map.get(@order_items, item.id, 0) == 0}
                  >
                    <.icon name="hero-minus-small" class="h-5 w-5" />
                  </button>

                  <span class="w-8 text-center font-medium">
                    <%= Map.get(@order_items, item.id, 0) %>
                  </span>

                  <button
                    type="button"
                    phx-click="increase_quantity"
                    phx-value-id={item.id}
                    phx-target={@myself}
                    class="rounded-full bg-gray-100 p-1 hover:bg-gray-200"
                  >
                    <.icon name="hero-plus-small" class="h-5 w-5" />
                  </button>
                </div>

                <span class="text-sm font-medium">
                  <%= Number.Currency.number_to_currency(item.price * Map.get(@order_items, item.id, 0)) %>
                </span>
              </div>
            </div>
          </div>

          <div class="mt-6 flex justify-end items-center space-x-4">
            <span class="text-lg font-medium">Total:</span>
            <span class="text-2xl font-bold"><%= Number.Currency.number_to_currency(@total) %></span>
          </div>
        </div>

        <.input field={@form[:prix_total]} type="hidden" value={@total} />
        <.input field={@form[:date_creation]} type="hidden" />

        <.input field={@form[:notes]} type="textarea" label="Notes générales" class="mt-6" />

        <:actions>
          <.button phx-disable-with="Enregistrement en cours...">
            <%= if @action == :new, do: "Créer la commande", else: "Mettre à jour la commande" %>
          </.button>
        </:actions>
      </.simple_form>

      <%= if @finding_optimal_headquarters do %>
        <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center">
          <div class="bg-white dark:bg-zinc-800 p-6 rounded-lg shadow-lg max-w-md w-full">
            <div class="flex flex-col items-center space-y-4">
              <div class="w-16 h-16 border-t-4 border-b-4 border-blue-500 rounded-full animate-spin"></div>
              <h3 class="text-lg font-semibold text-center">Calcul de l'itinéraire optimal</h3>
              <p class="text-sm text-gray-500 text-center">
                Nous recherchons le QG le plus adapté en fonction du stock disponible et du temps de trajet...
              </p>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{order: order} = assigns, socket) do
    available_items = Inventory.list_items_by_group(assigns.current_group.id)

    # Convert order items to a map of item_id => quantity
    order_items = if order.id do
      order = Orders.preload_order_items(order)
      order.order_items
      |> Enum.reduce(%{}, fn item, acc ->
        Map.put(acc, item.item_id, item.quantite)
      end)
    else
      %{}
    end

    total = calculate_total(order_items, available_items)
    changeset = Orders.change_order(order)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:available_items, available_items)
     |> assign(:order_items, order_items)
     |> assign(:total, total)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset =
      socket.assigns.order
      |> Orders.change_order(order_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("increase_quantity", %{"id" => item_id}, socket) do
    item_id = String.to_integer(item_id)
    order_items = Map.update(socket.assigns.order_items, item_id, 1, &(&1 + 1))
    total = calculate_total(order_items, socket.assigns.available_items)

    updated_socket =
      socket
      |> assign(:order_items, order_items)
      |> assign(:total, total)

    {:noreply, updated_socket}
  end

  def handle_event("decrease_quantity", %{"id" => item_id}, socket) do
    item_id = String.to_integer(item_id)
    current_quantity = Map.get(socket.assigns.order_items, item_id, 0)

    order_items = if current_quantity > 0 do
      Map.update(socket.assigns.order_items, item_id, 0, &(&1 - 1))
    else
      socket.assigns.order_items
    end

    total = calculate_total(order_items, socket.assigns.available_items)

    updated_socket =
      socket
      |> assign(:order_items, order_items)
      |> assign(:total, total)

    {:noreply, updated_socket}
  end

  def handle_event("save", %{"order" => order_params}, socket) do
    save_order(socket, socket.assigns.action, order_params)
  end

  def handle_event("search_address", %{"query" => query}, socket) when byte_size(query) > 2 do
    # Coordonnées de Grenoble pour centrer la recherche
    lat = 45.1885
    lon = 5.7245

    case search_address(query, lat, lon) do
      {:ok, suggestions} ->
        # Créer un map de lookup pour stocker les données complètes
        address_data = Enum.reduce(suggestions, %{}, fn feature, acc ->
          coords = feature["geometry"]["coordinates"]
          label = feature["properties"]["label"]
          data = %{
            label: label,
            lat: Enum.at(coords, 1), # Latitude est le second élément
            lon: Enum.at(coords, 0)  # Longitude est le premier élément
          }

          # Utiliser le label comme clé pour retrouver les données plus tard
          Map.put(acc, label, data)
        end)

        # Pour les options, utiliser seulement {label, label}
        address_suggestions = Enum.map(address_data, fn {label, _} -> {label, label} end)

        {:noreply,
          socket
          |> assign(:address_suggestions, address_suggestions)
          |> assign(:address_data, address_data)}

      _error ->
        {:noreply, assign(socket, :address_suggestions, [])}
    end
  end

  def handle_event("search_address", _params, socket) do
    {:noreply, assign(socket, :address_suggestions, [])}
  end

  def handle_event("select_address", %{"value" => selected_label}, socket) do
    # Récupérer les données complètes depuis notre map de lookup
    case Map.get(socket.assigns.address_data, selected_label) do
      nil ->
        {:noreply, socket}

      address_info ->
        changeset =
          socket.assigns.form.source
          |> Ecto.Changeset.put_change(:adresse_livraison, address_info.label)
          |> Ecto.Changeset.put_change(:latitude_livraison, address_info.lat)
          |> Ecto.Changeset.put_change(:longitude_livraison, address_info.lon)

        # Mise à jour du socket avec le changeset
        updated_socket = socket |> assign(:form, to_form(changeset))

        updated_socket
    end
  end

  @impl true
  def handle_info({:find_optimal_headquarters, product_quantities, address_info}, socket) do
    delivery_coordinates = {address_info.lat, address_info.lon}

    result = SoSinple.DeliveryOptimizer.select_best_headquarters(
      socket.assigns.current_group.id,
      product_quantities,
      delivery_coordinates
    )

    socket =
      case result do
        {:ok, %{headquarters: headquarters, travel_time: travel_time}} ->
          # Convertir le temps en minutes pour l'affichage
          travel_time_minutes = Float.round(travel_time / 60, 1)

          # Mettre à jour le formulaire avec le QG sélectionné
          changeset =
            socket.assigns.form.source
            |> Ecto.Changeset.put_change(:headquarters_id, headquarters.id)

          # Message de succès
          success_message = "Itinéraire optimisé ! Livraison depuis #{headquarters.name}. Temps de trajet estimé: #{travel_time_minutes} minutes."

          # Ajouter un message de notification
          socket
          |> assign(:form, to_form(changeset))
          |> assign(:needs_headquarters_update, false)
          |> put_flash(:info, success_message)

        {:error, :no_stock_available} ->
          socket
          |> put_flash(:error, "Aucun QG n'a le stock suffisant pour cette commande. Veuillez modifier votre commande ou contacter un administrateur.")

        {:error, :no_route_available} ->
          socket
          |> put_flash(:warning, "Impossible de calculer un itinéraire vers cette adresse. Veuillez sélectionner un QG manuellement.")

        {:error, _reason} ->
          socket
          |> put_flash(:error, "Une erreur est survenue lors de la sélection du QG. Veuillez contacter un administrateur.")
      end

    # Désactiver l'indicateur de recherche
    {:noreply, assign(socket, :finding_optimal_headquarters, false)}
  end

  defp search_address(query, lat, lon) do
    url = "https://api-adresse.data.gouv.fr/search/"
    params = %{
      q: query,
      lat: lat,
      lon: lon,
      limit: 5
    }

    case HTTPoison.get(url, [], params: params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"features" => features}} -> {:ok, features}
          _ -> {:error, :invalid_json}
        end
      _ -> {:error, :request_failed}
    end
  end

  defp save_order(socket, :new, order_params) do
    # Géocoder l'adresse avant la sauvegarde
    case geocode_address(order_params["adresse_livraison"]) do
      {:ok, %{lat: lat, lon: lon}} ->
        order_params = order_params
          |> Map.put("latitude_livraison", lat)
          |> Map.put("longitude_livraison", lon)

        # Convertir order_items en format attendu par DeliveryOptimizer
        product_quantities =
          socket.assigns.order_items
          |> Enum.filter(fn {_item_id, quantity} -> quantity > 0 end)
          |> Enum.map(fn {item_id, quantity} -> {item_id, quantity} end)
          |> Map.new()

        # Si la commande contient des articles, chercher le QG optimal
        if not Enum.empty?(product_quantities) do
          delivery_coordinates = {lat, lon}

          case SoSinple.DeliveryOptimizer.select_best_headquarters(
            socket.assigns.current_group.id,
            product_quantities,
            delivery_coordinates
          ) do
            {:ok, %{headquarters: headquarters, travel_time: travel_time}} ->
              # Ajouter le QG sélectionné aux paramètres de la commande
              order_params = Map.put(order_params, "headquarters_id", headquarters.id)

              # Préparer les paramètres des articles
              items_params = prepare_items_params(socket.assigns.order_items, socket.assigns.available_items)

              # Créer la commande avec le QG sélectionné
              case Orders.create_order_with_items(order_params, items_params) do
                {:ok, %{order: order}} ->
                  notify_parent({:saved, order})
                  travel_time_minutes = Float.round(travel_time / 60, 1)
                  success_message = "Commande créée avec succès ! Livraison depuis #{headquarters.name}. Temps de trajet estimé: #{travel_time_minutes} minutes."

                  {:noreply,
                   socket
                   |> put_flash(:info, success_message)
                   |> push_navigate(to: socket.assigns.patch)}

                {:error, _operation, changeset, _changes} ->
                  {:noreply, assign(socket, form: to_form(changeset))}
              end

            {:error, :no_stock_available} ->
              changeset = Orders.change_order(%SoSinple.Orders.Order{})
              {:noreply,
               socket
               |> assign(:form, to_form(changeset))
               |> put_flash(:error, "Aucun QG n'a le stock suffisant pour cette commande. Veuillez modifier votre commande ou contacter un administrateur.")}

            {:error, :no_route_available} ->
              changeset = Orders.change_order(%SoSinple.Orders.Order{})
              {:noreply,
               socket
               |> assign(:form, to_form(changeset))
               |> put_flash(:warning, "Impossible de calculer un itinéraire vers cette adresse. Veuillez sélectionner un QG manuellement.")}

            {:error, _reason} ->
              changeset = Orders.change_order(%SoSinple.Orders.Order{})
              {:noreply,
               socket
               |> assign(:form, to_form(changeset))
               |> put_flash(:error, "Une erreur est survenue lors de la sélection du QG. Veuillez contacter un administrateur.")}
          end
        else
          {:noreply,
           socket
           |> put_flash(:error, "Veuillez ajouter au moins un article à la commande.")}
        end

      _error ->
        {:noreply,
         socket
         |> put_flash(:error, "Impossible de géocoder l'adresse de livraison. Veuillez vérifier l'adresse.")}
    end
  end

  defp save_order(socket, :edit, order_params) do
    case Orders.update_order(socket.assigns.order, order_params) do
      {:ok, order} ->
        notify_parent({:saved, order})

        {:noreply,
         socket
         |> put_flash(:info, "Commande mise à jour avec succès")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp geocode_address(address) when is_binary(address) and address != "" do
    url = "https://api-adresse.data.gouv.fr/search/"
    params = %{
      q: address,
      limit: 1
    }

    case HTTPoison.get(url, [], params: params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"features" => [feature | _]}} ->
            coords = feature["geometry"]["coordinates"]
            {:ok, %{lat: Enum.at(coords, 1), lon: Enum.at(coords, 0)}}
          _ ->
            {:error, :no_results}
        end
      _ ->
        {:error, :request_failed}
    end
  end

  defp geocode_address(_), do: {:error, :invalid_address}

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp status_options do
    [
      {"En préparation", "preparation"},
      {"Prêt", "pret"},
      {"En livraison", "en_livraison"},
      {"Livré", "livre"},
      {"Annulé", "annule"}
    ]
  end

  defp headquarters_options(group_id) do
    Organizations.list_active_headquarters_by_group(group_id)
    |> Enum.map(fn hq -> {hq.name, hq.id} end)
  end

  defp calculate_total(order_items, available_items) do
    available_items
    |> Enum.reduce(0.0, fn item, acc ->
      quantity = Map.get(order_items, item.id, 0)
      acc + (item.price * quantity)
    end)
  end

  defp prepare_items_params(order_items, available_items) do
    available_items
    |> Enum.reduce([], fn item, acc ->
      case Map.get(order_items, item.id, 0) do
        0 -> acc
        quantity ->
          [%{
            "item_id" => item.id,
            "quantite" => quantity,
            "prix_unitaire" => item.price,
            "notes_speciales" => ""
          } | acc]
      end
    end)
  end

  defp get_headquarters_name(headquarters_id) when is_integer(headquarters_id) do
    case Organizations.get_headquarters!(headquarters_id) do
      %{name: name} -> name
      _ -> "Inconnu"
    end
  rescue
    _ -> "Inconnu"
  end

  defp get_headquarters_name(headquarters_id) when is_binary(headquarters_id) do
    case Integer.parse(headquarters_id) do
      {id, ""} -> get_headquarters_name(id)
      _ -> "Inconnu"
    end
  end

  defp get_headquarters_name(_), do: "Inconnu"
end
