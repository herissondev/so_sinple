defmodule SoSinpleWeb.StockItemLiveTest do
  use SoSinpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoSinple.InventoryFixtures

  @create_attrs %{available_quantity: 42, alert_threshold: 42}
  @update_attrs %{available_quantity: 43, alert_threshold: 43}
  @invalid_attrs %{available_quantity: nil, alert_threshold: nil}

  defp create_stock_item(_) do
    stock_item = stock_item_fixture()
    %{stock_item: stock_item}
  end

  describe "Index" do
    setup [:create_stock_item]

    test "lists all stock_items", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/stock_items")

      assert html =~ "Listing Stock items"
    end

    test "saves new stock_item", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/stock_items")

      assert index_live |> element("a", "New Stock item") |> render_click() =~
               "New Stock item"

      assert_patch(index_live, ~p"/stock_items/new")

      assert index_live
             |> form("#stock_item-form", stock_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#stock_item-form", stock_item: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/stock_items")

      html = render(index_live)
      assert html =~ "Stock item created successfully"
    end

    test "updates stock_item in listing", %{conn: conn, stock_item: stock_item} do
      {:ok, index_live, _html} = live(conn, ~p"/stock_items")

      assert index_live |> element("#stock_items-#{stock_item.id} a", "Edit") |> render_click() =~
               "Edit Stock item"

      assert_patch(index_live, ~p"/stock_items/#{stock_item}/edit")

      assert index_live
             |> form("#stock_item-form", stock_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#stock_item-form", stock_item: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/stock_items")

      html = render(index_live)
      assert html =~ "Stock item updated successfully"
    end

    test "deletes stock_item in listing", %{conn: conn, stock_item: stock_item} do
      {:ok, index_live, _html} = live(conn, ~p"/stock_items")

      assert index_live |> element("#stock_items-#{stock_item.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#stock_items-#{stock_item.id}")
    end
  end

  describe "Show" do
    setup [:create_stock_item]

    test "displays stock_item", %{conn: conn, stock_item: stock_item} do
      {:ok, _show_live, html} = live(conn, ~p"/stock_items/#{stock_item}")

      assert html =~ "Show Stock item"
    end

    test "updates stock_item within modal", %{conn: conn, stock_item: stock_item} do
      {:ok, show_live, _html} = live(conn, ~p"/stock_items/#{stock_item}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Stock item"

      assert_patch(show_live, ~p"/stock_items/#{stock_item}/show/edit")

      assert show_live
             |> form("#stock_item-form", stock_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#stock_item-form", stock_item: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/stock_items/#{stock_item}")

      html = render(show_live)
      assert html =~ "Stock item updated successfully"
    end
  end
end
