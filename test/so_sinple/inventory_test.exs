defmodule SoSinple.InventoryTest do
  use SoSinple.DataCase

  alias SoSinple.Inventory

  describe "items" do
    alias SoSinple.Inventory.Item

    import SoSinple.InventoryFixtures

    @invalid_attrs %{name: nil, description: nil, available: nil, price: nil, image_url: nil}

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Inventory.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Inventory.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      valid_attrs = %{name: "some name", description: "some description", available: true, price: 120.5, image_url: "some image_url"}

      assert {:ok, %Item{} = item} = Inventory.create_item(valid_attrs)
      assert item.name == "some name"
      assert item.description == "some description"
      assert item.available == true
      assert item.price == 120.5
      assert item.image_url == "some image_url"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", available: false, price: 456.7, image_url: "some updated image_url"}

      assert {:ok, %Item{} = item} = Inventory.update_item(item, update_attrs)
      assert item.name == "some updated name"
      assert item.description == "some updated description"
      assert item.available == false
      assert item.price == 456.7
      assert item.image_url == "some updated image_url"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_item(item, @invalid_attrs)
      assert item == Inventory.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Inventory.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Inventory.change_item(item)
    end
  end

  describe "stock_items" do
    alias SoSinple.Inventory.StockItem

    import SoSinple.InventoryFixtures

    @invalid_attrs %{available_quantity: nil, alert_threshold: nil}

    test "list_stock_items/0 returns all stock_items" do
      stock_item = stock_item_fixture()
      assert Inventory.list_stock_items() == [stock_item]
    end

    test "get_stock_item!/1 returns the stock_item with given id" do
      stock_item = stock_item_fixture()
      assert Inventory.get_stock_item!(stock_item.id) == stock_item
    end

    test "create_stock_item/1 with valid data creates a stock_item" do
      valid_attrs = %{available_quantity: 42, alert_threshold: 42}

      assert {:ok, %StockItem{} = stock_item} = Inventory.create_stock_item(valid_attrs)
      assert stock_item.available_quantity == 42
      assert stock_item.alert_threshold == 42
    end

    test "create_stock_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_stock_item(@invalid_attrs)
    end

    test "update_stock_item/2 with valid data updates the stock_item" do
      stock_item = stock_item_fixture()
      update_attrs = %{available_quantity: 43, alert_threshold: 43}

      assert {:ok, %StockItem{} = stock_item} = Inventory.update_stock_item(stock_item, update_attrs)
      assert stock_item.available_quantity == 43
      assert stock_item.alert_threshold == 43
    end

    test "update_stock_item/2 with invalid data returns error changeset" do
      stock_item = stock_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_stock_item(stock_item, @invalid_attrs)
      assert stock_item == Inventory.get_stock_item!(stock_item.id)
    end

    test "delete_stock_item/1 deletes the stock_item" do
      stock_item = stock_item_fixture()
      assert {:ok, %StockItem{}} = Inventory.delete_stock_item(stock_item)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_stock_item!(stock_item.id) end
    end

    test "change_stock_item/1 returns a stock_item changeset" do
      stock_item = stock_item_fixture()
      assert %Ecto.Changeset{} = Inventory.change_stock_item(stock_item)
    end
  end
end
