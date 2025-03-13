defmodule SoSinple.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SoSinple.Organizations` context.
  """

  @doc """
  Generate a group.
  """
  def group_fixture(attrs \\ %{}) do
    {:ok, group} =
      attrs
      |> Enum.into(%{
        active: true,
        description: "some description",
        name: "some name"
      })
      |> SoSinple.Organizations.create_group()

    group
  end

  @doc """
  Generate a headquarters.
  """
  def headquarters_fixture(attrs \\ %{}) do
    {:ok, headquarters} =
      attrs
      |> Enum.into(%{
        active: true,
        address: "some address",
        latitude: 120.5,
        longitude: 120.5,
        name: "some name",
        phone: "some phone"
      })
      |> SoSinple.Organizations.create_headquarters()

    headquarters
  end

  @doc """
  Generate a user_role.
  """
  def user_role_fixture(attrs \\ %{}) do
    {:ok, user_role} =
      attrs
      |> Enum.into(%{
        active: true,
        role: "some role"
      })
      |> SoSinple.Organizations.create_user_role()

    user_role
  end
end
