defmodule SoSinpleWeb.HeadquartersLiveTest do
  use SoSinpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoSinple.OrganizationsFixtures

  @create_attrs %{active: true, name: "some name", address: "some address", latitude: 120.5, longitude: 120.5, phone: "some phone"}
  @update_attrs %{active: false, name: "some updated name", address: "some updated address", latitude: 456.7, longitude: 456.7, phone: "some updated phone"}
  @invalid_attrs %{active: false, name: nil, address: nil, latitude: nil, longitude: nil, phone: nil}

  defp create_headquarters(_) do
    headquarters = headquarters_fixture()
    %{headquarters: headquarters}
  end

  describe "Index" do
    setup [:create_headquarters]

    test "lists all headquarters", %{conn: conn, headquarters: headquarters} do
      {:ok, _index_live, html} = live(conn, ~p"/headquarters")

      assert html =~ "Listing Headquarters"
      assert html =~ headquarters.name
    end

    test "saves new headquarters", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/headquarters")

      assert index_live |> element("a", "New Headquarters") |> render_click() =~
               "New Headquarters"

      assert_patch(index_live, ~p"/headquarters/new")

      assert index_live
             |> form("#headquarters-form", headquarters: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#headquarters-form", headquarters: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/headquarters")

      html = render(index_live)
      assert html =~ "Headquarters created successfully"
      assert html =~ "some name"
    end

    test "updates headquarters in listing", %{conn: conn, headquarters: headquarters} do
      {:ok, index_live, _html} = live(conn, ~p"/headquarters")

      assert index_live |> element("#headquarters-#{headquarters.id} a", "Edit") |> render_click() =~
               "Edit Headquarters"

      assert_patch(index_live, ~p"/headquarters/#{headquarters}/edit")

      assert index_live
             |> form("#headquarters-form", headquarters: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#headquarters-form", headquarters: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/headquarters")

      html = render(index_live)
      assert html =~ "Headquarters updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes headquarters in listing", %{conn: conn, headquarters: headquarters} do
      {:ok, index_live, _html} = live(conn, ~p"/headquarters")

      assert index_live |> element("#headquarters-#{headquarters.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#headquarters-#{headquarters.id}")
    end
  end

  describe "Show" do
    setup [:create_headquarters]

    test "displays headquarters", %{conn: conn, headquarters: headquarters} do
      {:ok, _show_live, html} = live(conn, ~p"/headquarters/#{headquarters}")

      assert html =~ "Show Headquarters"
      assert html =~ headquarters.name
    end

    test "updates headquarters within modal", %{conn: conn, headquarters: headquarters} do
      {:ok, show_live, _html} = live(conn, ~p"/headquarters/#{headquarters}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Headquarters"

      assert_patch(show_live, ~p"/headquarters/#{headquarters}/show/edit")

      assert show_live
             |> form("#headquarters-form", headquarters: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#headquarters-form", headquarters: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/headquarters/#{headquarters}")

      html = render(show_live)
      assert html =~ "Headquarters updated successfully"
      assert html =~ "some updated name"
    end
  end
end
