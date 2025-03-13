defmodule SoSinple.OrganizationsTest do
  use SoSinple.DataCase

  alias SoSinple.Organizations

  describe "groups" do
    alias SoSinple.Organizations.Group

    import SoSinple.OrganizationsFixtures

    @invalid_attrs %{active: nil, name: nil, description: nil}

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert Organizations.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert Organizations.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      valid_attrs = %{active: true, name: "some name", description: "some description"}

      assert {:ok, %Group{} = group} = Organizations.create_group(valid_attrs)
      assert group.active == true
      assert group.name == "some name"
      assert group.description == "some description"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      update_attrs = %{active: false, name: "some updated name", description: "some updated description"}

      assert {:ok, %Group{} = group} = Organizations.update_group(group, update_attrs)
      assert group.active == false
      assert group.name == "some updated name"
      assert group.description == "some updated description"
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = Organizations.update_group(group, @invalid_attrs)
      assert group == Organizations.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = Organizations.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> Organizations.get_group!(group.id) end
    end

    test "change_group/1 returns a group changeset" do
      group = group_fixture()
      assert %Ecto.Changeset{} = Organizations.change_group(group)
    end
  end

  describe "headquarters" do
    alias SoSinple.Organizations.Headquarters

    import SoSinple.OrganizationsFixtures

    @invalid_attrs %{active: nil, name: nil, address: nil, latitude: nil, longitude: nil, phone: nil}

    test "list_headquarters/0 returns all headquarters" do
      headquarters = headquarters_fixture()
      assert Organizations.list_headquarters() == [headquarters]
    end

    test "get_headquarters!/1 returns the headquarters with given id" do
      headquarters = headquarters_fixture()
      assert Organizations.get_headquarters!(headquarters.id) == headquarters
    end

    test "create_headquarters/1 with valid data creates a headquarters" do
      valid_attrs = %{active: true, name: "some name", address: "some address", latitude: 120.5, longitude: 120.5, phone: "some phone"}

      assert {:ok, %Headquarters{} = headquarters} = Organizations.create_headquarters(valid_attrs)
      assert headquarters.active == true
      assert headquarters.name == "some name"
      assert headquarters.address == "some address"
      assert headquarters.latitude == 120.5
      assert headquarters.longitude == 120.5
      assert headquarters.phone == "some phone"
    end

    test "create_headquarters/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_headquarters(@invalid_attrs)
    end

    test "update_headquarters/2 with valid data updates the headquarters" do
      headquarters = headquarters_fixture()
      update_attrs = %{active: false, name: "some updated name", address: "some updated address", latitude: 456.7, longitude: 456.7, phone: "some updated phone"}

      assert {:ok, %Headquarters{} = headquarters} = Organizations.update_headquarters(headquarters, update_attrs)
      assert headquarters.active == false
      assert headquarters.name == "some updated name"
      assert headquarters.address == "some updated address"
      assert headquarters.latitude == 456.7
      assert headquarters.longitude == 456.7
      assert headquarters.phone == "some updated phone"
    end

    test "update_headquarters/2 with invalid data returns error changeset" do
      headquarters = headquarters_fixture()
      assert {:error, %Ecto.Changeset{}} = Organizations.update_headquarters(headquarters, @invalid_attrs)
      assert headquarters == Organizations.get_headquarters!(headquarters.id)
    end

    test "delete_headquarters/1 deletes the headquarters" do
      headquarters = headquarters_fixture()
      assert {:ok, %Headquarters{}} = Organizations.delete_headquarters(headquarters)
      assert_raise Ecto.NoResultsError, fn -> Organizations.get_headquarters!(headquarters.id) end
    end

    test "change_headquarters/1 returns a headquarters changeset" do
      headquarters = headquarters_fixture()
      assert %Ecto.Changeset{} = Organizations.change_headquarters(headquarters)
    end
  end

  describe "user_roles" do
    alias SoSinple.Organizations.UserRole

    import SoSinple.OrganizationsFixtures

    @invalid_attrs %{active: nil, role: nil}

    test "list_user_roles/0 returns all user_roles" do
      user_role = user_role_fixture()
      assert Organizations.list_user_roles() == [user_role]
    end

    test "get_user_role!/1 returns the user_role with given id" do
      user_role = user_role_fixture()
      assert Organizations.get_user_role!(user_role.id) == user_role
    end

    test "create_user_role/1 with valid data creates a user_role" do
      valid_attrs = %{active: true, role: "some role"}

      assert {:ok, %UserRole{} = user_role} = Organizations.create_user_role(valid_attrs)
      assert user_role.active == true
      assert user_role.role == "some role"
    end

    test "create_user_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_user_role(@invalid_attrs)
    end

    test "update_user_role/2 with valid data updates the user_role" do
      user_role = user_role_fixture()
      update_attrs = %{active: false, role: "some updated role"}

      assert {:ok, %UserRole{} = user_role} = Organizations.update_user_role(user_role, update_attrs)
      assert user_role.active == false
      assert user_role.role == "some updated role"
    end

    test "update_user_role/2 with invalid data returns error changeset" do
      user_role = user_role_fixture()
      assert {:error, %Ecto.Changeset{}} = Organizations.update_user_role(user_role, @invalid_attrs)
      assert user_role == Organizations.get_user_role!(user_role.id)
    end

    test "delete_user_role/1 deletes the user_role" do
      user_role = user_role_fixture()
      assert {:ok, %UserRole{}} = Organizations.delete_user_role(user_role)
      assert_raise Ecto.NoResultsError, fn -> Organizations.get_user_role!(user_role.id) end
    end

    test "change_user_role/1 returns a user_role changeset" do
      user_role = user_role_fixture()
      assert %Ecto.Changeset{} = Organizations.change_user_role(user_role)
    end
  end
end
