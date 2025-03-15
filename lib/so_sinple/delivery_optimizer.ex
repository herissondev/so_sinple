defmodule SoSinple.DeliveryOptimizer do
  @moduledoc """
  Module responsible for optimizing delivery operations by selecting the best headquarters
  for a given order based on stock availability and travel time.
  """

  alias SoSinple.Organizations
  alias SoSinple.Inventory

  @doc """
  Selects the best headquarters for a new order based on:
  1. Stock availability
  2. Travel time to delivery address

  Returns `{:ok, %{headquarters: headquarters, travel_time: travel_time}}` or `{:error, reason}`
  """
  def select_best_headquarters(group_id, product_quantities, delivery_coordinates) do
    with {:ok, headquarters_with_stock} <- filter_headquarters_by_stock(group_id, product_quantities),
         {:ok, best_match} <- find_fastest_headquarters(headquarters_with_stock, delivery_coordinates) do
      {:ok, best_match}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Filters headquarters by stock availability for all products in the order.
  """
  defp filter_headquarters_by_stock(group_id, product_quantities) do
    headquarters = Organizations.list_active_headquarters_by_group(group_id)

    headquarters_with_stock = Enum.filter(headquarters, fn hq ->
      has_sufficient_stock?(hq.id, product_quantities)
    end)

    case headquarters_with_stock do
      [] -> {:error, :no_stock_available}
      filtered -> {:ok, filtered}
    end
  end

  @doc """
  Checks if a headquarters has sufficient stock for all products in the order.
  """
  defp has_sufficient_stock?(headquarters_id, product_quantities) do
    Enum.all?(product_quantities, fn {product_id, quantity} ->
      case Inventory.get_stock_level(headquarters_id, product_id) do
        {:ok, stock} ->
          IO.inspect(stock)
          IO.inspect(quantity)
          stock >= quantity
        _ -> false
      end
    end)
  end

  @doc """
  Finds the headquarters with the shortest travel time to the delivery address.
  Uses the Métromobilité API to calculate travel times.
  """
  defp find_fastest_headquarters(headquarters_list, {delivery_lat, delivery_lon}) do
    tasks = Enum.map(headquarters_list, fn hq ->
      Task.async(fn ->
        case get_travel_time(hq, {delivery_lat, delivery_lon}) do
          {:ok, travel_time} -> {hq, travel_time}
          _ -> {hq, :infinity}
        end
      end)
    end)

    results = Task.await_many(tasks, 10_000)

    case Enum.min_by(results, fn {_hq, time} ->
      case time do
        :infinity -> :infinity
        time when is_number(time) -> time
      end
    end) do
      {hq, :infinity} -> {:error, :no_route_available}
      {hq, travel_time} -> {:ok, %{headquarters: hq, travel_time: travel_time}}
    end
  end

  @doc """
  Calculates travel time between a headquarters and delivery address using the Métromobilité API.
  Returns travel time in seconds.
  """
  defp get_travel_time(headquarters, {delivery_lat, delivery_lon}) do
    url = "https://data.mobilites-m.fr/api/routers/default/plan?" <>
          "fromPlace=#{headquarters.latitude},#{headquarters.longitude}&" <>
          "toPlace=#{delivery_lat},#{delivery_lon}&" <>
          "mode=BICYCLE"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"plan" => %{"itineraries" => [%{"duration" => duration} | _]}}} ->
            {:ok, duration}
          _ ->
            {:error, :invalid_response}
        end
      _ ->
        {:error, :request_failed}
    end
  end
end
