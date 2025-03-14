defmodule SoSinpleWeb.OrderItemLiveTest do
  use SoSinpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoSinple.OrdersFixtures

  @create_attrs %{quantite: 42, prix_unitaire: 120.5, notes_speciales: "some notes_speciales"}
  @update_attrs %{quantite: 43, prix_unitaire: 456.7, notes_speciales: "some updated notes_speciales"}
  @invalid_attrs %{quantite: nil, prix_unitaire: nil, notes_speciales: nil}

  defp create_order_item(_) do
    order_item = order_item_fixture()
    %{order_item: order_item}
  end

  describe "Index" do
    setup [:create_order_item]

    test "lists all order_items", %{conn: conn, order_item: order_item} do
      {:ok, _index_live, html} = live(conn, ~p"/order_items")

      assert html =~ "Listing Order items"
      assert html =~ order_item.notes_speciales
    end

    test "saves new order_item", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/order_items")

      assert index_live |> element("a", "New Order item") |> render_click() =~
               "New Order item"

      assert_patch(index_live, ~p"/order_items/new")

      assert index_live
             |> form("#order_item-form", order_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#order_item-form", order_item: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/order_items")

      html = render(index_live)
      assert html =~ "Order item created successfully"
      assert html =~ "some notes_speciales"
    end

    test "updates order_item in listing", %{conn: conn, order_item: order_item} do
      {:ok, index_live, _html} = live(conn, ~p"/order_items")

      assert index_live |> element("#order_items-#{order_item.id} a", "Edit") |> render_click() =~
               "Edit Order item"

      assert_patch(index_live, ~p"/order_items/#{order_item}/edit")

      assert index_live
             |> form("#order_item-form", order_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#order_item-form", order_item: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/order_items")

      html = render(index_live)
      assert html =~ "Order item updated successfully"
      assert html =~ "some updated notes_speciales"
    end

    test "deletes order_item in listing", %{conn: conn, order_item: order_item} do
      {:ok, index_live, _html} = live(conn, ~p"/order_items")

      assert index_live |> element("#order_items-#{order_item.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#order_items-#{order_item.id}")
    end
  end

  describe "Show" do
    setup [:create_order_item]

    test "displays order_item", %{conn: conn, order_item: order_item} do
      {:ok, _show_live, html} = live(conn, ~p"/order_items/#{order_item}")

      assert html =~ "Show Order item"
      assert html =~ order_item.notes_speciales
    end

    test "updates order_item within modal", %{conn: conn, order_item: order_item} do
      {:ok, show_live, _html} = live(conn, ~p"/order_items/#{order_item}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Order item"

      assert_patch(show_live, ~p"/order_items/#{order_item}/show/edit")

      assert show_live
             |> form("#order_item-form", order_item: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#order_item-form", order_item: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/order_items/#{order_item}")

      html = render(show_live)
      assert html =~ "Order item updated successfully"
      assert html =~ "some updated notes_speciales"
    end
  end
end
