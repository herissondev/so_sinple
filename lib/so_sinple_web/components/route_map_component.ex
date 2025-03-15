defmodule SoSinpleWeb.RouteMapComponent do
  use SoSinpleWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="w-full h-[500px] relative rounded-lg overflow-hidden shadow-lg" id={"route-map-#{@id}"} phx-hook="RouteMapHook" data-from-coords={Jason.encode!(@from_coords)} data-to-coords={Jason.encode!(@to_coords)} data-encoded-route={@encoded_route}>
      <div class="absolute inset-0" id={"route-map-container-#{@id}"}></div>
    </div>
    """
  end
end
