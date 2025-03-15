defmodule SoSinpleWeb.MapComponent do
  use SoSinpleWeb, :live_component

  def render(assigns) do
    ~H"""

    <div class="w-full h-[500px] relative rounded-lg overflow-hidden shadow-lg" id={"map-#{@id}"} phx-hook="MapHook" data-headquarters={Jason.encode!(@headquarters)} data-orders={Jason.encode!(@orders)}>
      <div class="absolute inset-0" id={"map-container-#{@id}"}></div>
    </div>
    """
  end
end
