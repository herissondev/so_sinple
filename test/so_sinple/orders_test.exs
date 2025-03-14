defmodule SoSinple.OrdersTest do
  use SoSinple.DataCase

  alias SoSinple.Orders

  describe "orders" do
    alias SoSinple.Orders.Order

    import SoSinple.OrdersFixtures

    @invalid_attrs %{status: nil, date_creation: nil, date_livraison_prevue: nil, client_nom: nil, client_prenom: nil, client_adresse: nil, client_telephone: nil, prix_total: nil, adresse_livraison: nil, latitude_livraison: nil, longitude_livraison: nil, notes: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{status: "some status", date_creation: ~U[2025-03-12 21:58:00Z], date_livraison_prevue: ~U[2025-03-12 21:58:00Z], client_nom: "some client_nom", client_prenom: "some client_prenom", client_adresse: "some client_adresse", client_telephone: "some client_telephone", prix_total: 120.5, adresse_livraison: "some adresse_livraison", latitude_livraison: 120.5, longitude_livraison: 120.5, notes: "some notes"}

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.status == "some status"
      assert order.date_creation == ~U[2025-03-12 21:58:00Z]
      assert order.date_livraison_prevue == ~U[2025-03-12 21:58:00Z]
      assert order.client_nom == "some client_nom"
      assert order.client_prenom == "some client_prenom"
      assert order.client_adresse == "some client_adresse"
      assert order.client_telephone == "some client_telephone"
      assert order.prix_total == 120.5
      assert order.adresse_livraison == "some adresse_livraison"
      assert order.latitude_livraison == 120.5
      assert order.longitude_livraison == 120.5
      assert order.notes == "some notes"
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{status: "some updated status", date_creation: ~U[2025-03-13 21:58:00Z], date_livraison_prevue: ~U[2025-03-13 21:58:00Z], client_nom: "some updated client_nom", client_prenom: "some updated client_prenom", client_adresse: "some updated client_adresse", client_telephone: "some updated client_telephone", prix_total: 456.7, adresse_livraison: "some updated adresse_livraison", latitude_livraison: 456.7, longitude_livraison: 456.7, notes: "some updated notes"}

      assert {:ok, %Order{} = order} = Orders.update_order(order, update_attrs)
      assert order.status == "some updated status"
      assert order.date_creation == ~U[2025-03-13 21:58:00Z]
      assert order.date_livraison_prevue == ~U[2025-03-13 21:58:00Z]
      assert order.client_nom == "some updated client_nom"
      assert order.client_prenom == "some updated client_prenom"
      assert order.client_adresse == "some updated client_adresse"
      assert order.client_telephone == "some updated client_telephone"
      assert order.prix_total == 456.7
      assert order.adresse_livraison == "some updated adresse_livraison"
      assert order.latitude_livraison == 456.7
      assert order.longitude_livraison == 456.7
      assert order.notes == "some updated notes"
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, @invalid_attrs)
      assert order == Orders.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end
  end

  describe "order_items" do
    alias SoSinple.Orders.OrderItem

    import SoSinple.OrdersFixtures

    @invalid_attrs %{quantite: nil, prix_unitaire: nil, notes_speciales: nil}

    test "list_order_items/0 returns all order_items" do
      order_item = order_item_fixture()
      assert Orders.list_order_items() == [order_item]
    end

    test "get_order_item!/1 returns the order_item with given id" do
      order_item = order_item_fixture()
      assert Orders.get_order_item!(order_item.id) == order_item
    end

    test "create_order_item/1 with valid data creates a order_item" do
      valid_attrs = %{quantite: 42, prix_unitaire: 120.5, notes_speciales: "some notes_speciales"}

      assert {:ok, %OrderItem{} = order_item} = Orders.create_order_item(valid_attrs)
      assert order_item.quantite == 42
      assert order_item.prix_unitaire == 120.5
      assert order_item.notes_speciales == "some notes_speciales"
    end

    test "create_order_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order_item(@invalid_attrs)
    end

    test "update_order_item/2 with valid data updates the order_item" do
      order_item = order_item_fixture()
      update_attrs = %{quantite: 43, prix_unitaire: 456.7, notes_speciales: "some updated notes_speciales"}

      assert {:ok, %OrderItem{} = order_item} = Orders.update_order_item(order_item, update_attrs)
      assert order_item.quantite == 43
      assert order_item.prix_unitaire == 456.7
      assert order_item.notes_speciales == "some updated notes_speciales"
    end

    test "update_order_item/2 with invalid data returns error changeset" do
      order_item = order_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order_item(order_item, @invalid_attrs)
      assert order_item == Orders.get_order_item!(order_item.id)
    end

    test "delete_order_item/1 deletes the order_item" do
      order_item = order_item_fixture()
      assert {:ok, %OrderItem{}} = Orders.delete_order_item(order_item)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order_item!(order_item.id) end
    end

    test "change_order_item/1 returns a order_item changeset" do
      order_item = order_item_fixture()
      assert %Ecto.Changeset{} = Orders.change_order_item(order_item)
    end
  end

  describe "orders" do
    alias SoSinple.Orders.Order

    import SoSinple.OrdersFixtures

    @invalid_attrs %{status: nil, date_creation: nil, date_livraison_prevue: nil, client_nom: nil, client_prenom: nil, client_adresse: nil, client_telephone: nil, prix_total: nil, adresse_livraison: nil, latitude_livraison: nil, longitude_livraison: nil, notes: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{status: "some status", date_creation: ~N[2025-03-12 22:03:00], date_livraison_prevue: ~N[2025-03-12 22:03:00], client_nom: "some client_nom", client_prenom: "some client_prenom", client_adresse: "some client_adresse", client_telephone: "some client_telephone", prix_total: 120.5, adresse_livraison: "some adresse_livraison", latitude_livraison: 120.5, longitude_livraison: 120.5, notes: "some notes"}

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.status == "some status"
      assert order.date_creation == ~N[2025-03-12 22:03:00]
      assert order.date_livraison_prevue == ~N[2025-03-12 22:03:00]
      assert order.client_nom == "some client_nom"
      assert order.client_prenom == "some client_prenom"
      assert order.client_adresse == "some client_adresse"
      assert order.client_telephone == "some client_telephone"
      assert order.prix_total == 120.5
      assert order.adresse_livraison == "some adresse_livraison"
      assert order.latitude_livraison == 120.5
      assert order.longitude_livraison == 120.5
      assert order.notes == "some notes"
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{status: "some updated status", date_creation: ~N[2025-03-13 22:03:00], date_livraison_prevue: ~N[2025-03-13 22:03:00], client_nom: "some updated client_nom", client_prenom: "some updated client_prenom", client_adresse: "some updated client_adresse", client_telephone: "some updated client_telephone", prix_total: 456.7, adresse_livraison: "some updated adresse_livraison", latitude_livraison: 456.7, longitude_livraison: 456.7, notes: "some updated notes"}

      assert {:ok, %Order{} = order} = Orders.update_order(order, update_attrs)
      assert order.status == "some updated status"
      assert order.date_creation == ~N[2025-03-13 22:03:00]
      assert order.date_livraison_prevue == ~N[2025-03-13 22:03:00]
      assert order.client_nom == "some updated client_nom"
      assert order.client_prenom == "some updated client_prenom"
      assert order.client_adresse == "some updated client_adresse"
      assert order.client_telephone == "some updated client_telephone"
      assert order.prix_total == 456.7
      assert order.adresse_livraison == "some updated adresse_livraison"
      assert order.latitude_livraison == 456.7
      assert order.longitude_livraison == 456.7
      assert order.notes == "some updated notes"
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, @invalid_attrs)
      assert order == Orders.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end
  end
end
