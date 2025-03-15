defmodule SoSinpleWeb.DeliveryLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders
  alias SoSinple.Orders.Order
  alias SoSinple.Repo

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(id) |> Orders.preload_order_items() |> Repo.preload(:headquarters)

    # Vérifier que le livreur est assigné à cette commande
    if order.livreur_id == socket.assigns.current_user.id do
      # Fetch route data if delivery address coordinates exist
      route_data = if order.latitude_livraison && order.longitude_livraison &&
                      order.headquarters.latitude && order.headquarters.longitude do
        fetch_route_data(
          {order.headquarters.latitude, order.headquarters.longitude},
          {order.latitude_livraison, order.longitude_livraison}
        )
      else
        nil
      end

      # Extract encoded route if available
      encoded_route = if route_data != nil do
        case get_in(route_data, ["plan", "itineraries"]) do
          [first_itinerary | _] ->
            case get_in(first_itinerary, ["legs"]) do
              [first_leg | _] -> get_in(first_leg, ["legGeometry", "points"])
              _ -> nil
            end
          _ -> nil
        end
      else
        nil
      end

      {:ok, socket
      |> assign(:order, order)
      |> assign(:page_title, "Commande ##{order.id}")
      |> assign(:route_data, route_data)
      |> assign(:encoded_route, encoded_route)
      |> assign(:from_coords, [order.headquarters.latitude, order.headquarters.longitude])
      |> assign(:to_coords, [order.latitude_livraison, order.longitude_livraison])}
    else
      {:ok, socket
      |> put_flash(:error, "Vous n'avez pas accès à cette commande.")
      |> push_redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/delivery")}
    end
  end

  @impl true
  def handle_params(%{"id" => _id}, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("complete_delivery", %{"id" => id}, socket) do
    order = Orders.get_order!(id)

    # Vérifier que le livreur est bien assigné à cette commande
    if order.livreur_id == socket.assigns.current_user.id do
      case Orders.complete_delivery(order) do
        {:ok, _updated_order} ->
          {:noreply, socket
           |> put_flash(:info, "Commande marquée comme livrée.")
           |> push_redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/delivery")}

        {:error, changeset} ->
          {:noreply, socket
           |> put_flash(:error, "Erreur lors de la mise à jour de la commande: #{inspect(changeset.errors)}")}
      end
    else
      {:noreply, socket
      |> put_flash(:error, "Vous n'êtes pas autorisé à modifier cette commande.")}
    end
  end

  @impl true
  def handle_event("cancel_delivery", %{"id" => id}, socket) do
    order = Orders.get_order!(id)

    # Vérifier que le livreur est bien assigné à cette commande
    if order.livreur_id == socket.assigns.current_user.id do
      case Orders.cancel_delivery(order) do
        {:ok, _updated_order} ->
          {:noreply, socket
           |> put_flash(:info, "Livraison annulée.")
           |> push_redirect(to: ~p"/groups/#{socket.assigns.current_group.id}/delivery")}

        {:error, changeset} ->
          {:noreply, socket
           |> put_flash(:error, "Erreur lors de l'annulation de la commande: #{inspect(changeset.errors)}")}
      end
    else
      {:noreply, socket
      |> put_flash(:error, "Vous n'êtes pas autorisé à modifier cette commande.")}
    end
  end

  @impl true
  def handle_event("open_navigation", %{"latitude" => latitude, "longitude" => longitude}, socket) do
    maps_url = "https://www.google.com/maps/dir/?api=1&destination=#{latitude},#{longitude}"
    {:noreply, push_event(socket, "redirect", %{to: maps_url})}
  end

  # Fonction pour construire l'URL de navigation selon la plateforme
  defp build_navigation_url(latitude, longitude) do
    # URL générique qui fonctionne sur la plupart des plateformes
    "https://www.google.com/maps/dir/?api=1&destination=#{latitude},#{longitude}"
  end

  # Fetch route data from the mobilites-m.fr API
  defp fetch_route_data({from_lat, from_lng}, {to_lat, to_lng}) do
    url = "https://data.mobilites-m.fr/api/routers/default/plan?fromPlace=#{from_lat},#{from_lng}&toPlace=#{to_lat},#{to_lng}&mode=BICYCLE"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> data
          _ -> nil
        end
      _ ->
        nil
    end
  end
end
