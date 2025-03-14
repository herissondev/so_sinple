defmodule SoSinpleWeb.OrderLiveTest do
  use SoSinpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoSinple.OrdersFixtures

  @create_attrs %{status: "some status", date_creation: "2025-03-12T22:03:00", date_livraison_prevue: "2025-03-12T22:03:00", client_nom: "some client_nom", client_prenom: "some client_prenom", client_adresse: "some client_adresse", client_telephone: "some client_telephone", prix_total: 120.5, adresse_livraison: "some adresse_livraison", latitude_livraison: 120.5, longitude_livraison: 120.5, notes: "some notes"}
  @update_attrs %{status: "some updated status", date_creation: "2025-03-13T22:03:00", date_livraison_prevue: "2025-03-13T22:03:00", client_nom: "some updated client_nom", client_prenom: "some updated client_prenom", client_adresse: "some updated client_adresse", client_telephone: "some updated client_telephone", prix_total: 456.7, adresse_livraison: "some updated adresse_livraison", latitude_livraison: 456.7, longitude_livraison: 456.7, notes: "some updated notes"}
  @invalid_attrs %{status: nil, date_creation: nil, date_livraison_prevue: nil, client_nom: nil, client_prenom: nil, client_adresse: nil, client_telephone: nil, prix_total: nil, adresse_livraison: nil, latitude_livraison: nil, longitude_livraison: nil, notes: nil}

  defp create_order(_) do
    order = order_fixture()
    %{order: order}
  end

  describe "Index" do
    setup [:create_order]

    test "lists all orders", %{conn: conn, order: order} do
      {:ok, _index_live, html} = live(conn, ~p"/orders")

      assert html =~ "Listing Orders"
      assert html =~ order.status
    end

    test "saves new order", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert index_live |> element("a", "New Order") |> render_click() =~
               "New Order"

      assert_patch(index_live, ~p"/orders/new")

      assert index_live
             |> form("#order-form", order: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#order-form", order: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/orders")

      html = render(index_live)
      assert html =~ "Order created successfully"
      assert html =~ "some status"
    end

    test "updates order in listing", %{conn: conn, order: order} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert index_live |> element("#orders-#{order.id} a", "Edit") |> render_click() =~
               "Edit Order"

      assert_patch(index_live, ~p"/orders/#{order}/edit")

      assert index_live
             |> form("#order-form", order: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#order-form", order: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/orders")

      html = render(index_live)
      assert html =~ "Order updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes order in listing", %{conn: conn, order: order} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert index_live |> element("#orders-#{order.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#orders-#{order.id}")
    end
  end

  describe "Show" do
    setup [:create_order]

    test "displays order", %{conn: conn, order: order} do
      {:ok, _show_live, html} = live(conn, ~p"/orders/#{order}")

      assert html =~ "Show Order"
      assert html =~ order.status
    end

    test "updates order within modal", %{conn: conn, order: order} do
      {:ok, show_live, _html} = live(conn, ~p"/orders/#{order}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Order"

      assert_patch(show_live, ~p"/orders/#{order}/show/edit")

      assert show_live
             |> form("#order-form", order: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#order-form", order: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/orders/#{order}")

      html = render(show_live)
      assert html =~ "Order updated successfully"
      assert html =~ "some updated status"
    end
  end
end
