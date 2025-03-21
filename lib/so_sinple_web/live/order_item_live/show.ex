defmodule SoSinpleWeb.OrderItemLive.Show do
  use SoSinpleWeb, :live_view

  alias SoSinple.Orders

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:order_item, Orders.get_order_item!(id))}
  end

  defp page_title(:show), do: "Show Order item"
  defp page_title(:edit), do: "Edit Order item"
end
