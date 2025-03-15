defmodule SoSinple.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false
  alias SoSinple.Repo

  alias SoSinple.Organizations.Group
  alias SoSinple.Organizations.UserRole

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups do
    Repo.all(Group)
  end

  @doc """
  Returns the list of groups for a specific user.
  Includes groups where the user is admin or has a role.
  """
  def list_user_groups(user_id) do
    # Groupes où l'utilisateur est admin
    admin_groups_query = from g in Group,
      where: g.admin_id == ^user_id

    # Groupes où l'utilisateur a un rôle
    role_groups_query = from g in Group,
      join: ur in UserRole, on: ur.group_id == g.id,
      where: ur.user_id == ^user_id and ur.active == true,
      distinct: true

    # Combiner les deux requêtes
    admin_groups = Repo.all(admin_groups_query)
    role_groups = Repo.all(role_groups_query)

    # Éliminer les doublons
    (admin_groups ++ role_groups)
    |> Enum.uniq_by(fn g -> g.id end)
  end

  @doc """
  Returns the list of active groups for a specific user.
  """
  def list_active_user_groups(user_id) do
    list_user_groups(user_id)
    |> Enum.filter(fn g -> g.active end)
  end

  @doc """
  Returns the list of active groups.
  """
  def list_active_groups do
    Group
    |> where([g], g.active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single group.

  Raises `Ecto.NoResultsError` if the Group does not exist.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group!(id), do: Repo.get!(Group, id)

  @doc """
  Gets a single group with preloaded admin.
  """
  def get_group_with_admin!(id) do
    Group
    |> Repo.get!(id)
    |> Repo.preload(:admin)
  end

  @doc """
  Gets a single group with preloaded headquarters.
  """
  def get_group_with_headquarters!(id) do
    Group
    |> Repo.get!(id)
    |> Repo.preload(:headquarters)
  end

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Group{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a group.

  ## Examples

      iex> update_group(group, %{field: new_value})
      {:ok, %Group{}}

      iex> update_group(group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group changes.

  ## Examples

      iex> change_group(group)
      %Ecto.Changeset{data: %Group{}}

  """
  def change_group(%Group{} = group, attrs \\ %{}) do
    Group.changeset(group, attrs)
  end

  alias SoSinple.Organizations.Headquarters

  @doc """
  Returns the list of headquarters.

  ## Examples

      iex> list_headquarters()
      [%Headquarters{}, ...]

  """
  def list_headquarters do
    Repo.all(Headquarters)
  end

  @doc """
  Returns the list of active headquarters.
  """
  def list_active_headquarters do
    Headquarters
    |> where([h], h.active == true)
    |> Repo.all()
  end

  @doc """
  Returns the list of headquarters for a specific group.
  """
  def list_headquarters_by_group(group_id) do
    Headquarters
    |> where([h], h.group_id == ^group_id)
    |> Repo.all()
  end

  @doc """
  Returns the list of active headquarters for a specific group.
  """
  def list_active_headquarters_by_group(group_id) do
    Headquarters
    |> where([h], h.group_id == ^group_id and h.active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single headquarters.

  Raises `Ecto.NoResultsError` if the Headquarters does not exist.

  ## Examples

      iex> get_headquarters!(123)
      %Headquarters{}

      iex> get_headquarters!(456)
      ** (Ecto.NoResultsError)

  """
  def get_headquarters!(id), do: Repo.get!(Headquarters, id)

  @doc """
  Gets a single headquarters with preloaded group.
  """
  def get_headquarters_with_group!(id) do
    Headquarters
    |> Repo.get!(id)
    |> Repo.preload(:group)
  end

  @doc """
  Creates a headquarters.

  ## Examples

      iex> create_headquarters(%{field: value})
      {:ok, %Headquarters{}}

      iex> create_headquarters(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_headquarters(attrs \\ %{}) do
    %Headquarters{}
    |> Headquarters.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a headquarters.

  ## Examples

      iex> update_headquarters(headquarters, %{field: new_value})
      {:ok, %Headquarters{}}

      iex> update_headquarters(headquarters, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_headquarters(%Headquarters{} = headquarters, attrs) do
    headquarters
    |> Headquarters.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a headquarters.

  ## Examples

      iex> delete_headquarters(headquarters)
      {:ok, %Headquarters{}}

      iex> delete_headquarters(headquarters)
      {:error, %Ecto.Changeset{}}

  """
  def delete_headquarters(%Headquarters{} = headquarters) do
    Repo.delete(headquarters)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking headquarters changes.

  ## Examples

      iex> change_headquarters(headquarters)
      %Ecto.Changeset{data: %Headquarters{}}

  """
  def change_headquarters(%Headquarters{} = headquarters, attrs \\ %{}) do
    Headquarters.changeset(headquarters, attrs)
  end

  alias SoSinple.Organizations.UserRole

  @doc """
  Returns the list of user_roles.

  ## Examples

      iex> list_user_roles()
      [%UserRole{}, ...]

  """
  def list_user_roles do
    Repo.all(UserRole)
  end

  @doc """
  Returns the list of active user_roles.
  """
  def list_active_user_roles do
    UserRole
    |> where([ur], ur.active == true)
    |> Repo.all()
  end

  @doc """
  Returns the list of user_roles for a specific user.
  """
  def list_user_roles_by_user(user_id) do
    UserRole
    |> where([ur], ur.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload([:group, :headquarters])
  end

  @doc """
  Returns the list of active user_roles for a specific user.
  """
  def list_active_user_roles_by_user(user_id) do
    UserRole
    |> where([ur], ur.user_id == ^user_id and ur.active == true)
    |> Repo.all()
    |> Repo.preload([:group, :headquarters])
  end

  @doc """
  Returns the list of user_roles for a specific group.
  """
  def list_user_roles_by_group(group_id) do
    UserRole
    |> where([ur], ur.group_id == ^group_id)
    |> Repo.all()
    |> Repo.preload([:user, :headquarters])
  end

  @doc """
  Returns the list of user_roles for a specific headquarters.
  """
  def list_user_roles_by_headquarters(headquarters_id) do
    UserRole
    |> where([ur], ur.headquarters_id == ^headquarters_id)
    |> Repo.all()
    |> Repo.preload([:user, :group])
  end

  @doc """
  Gets a single user_role.

  Raises `Ecto.NoResultsError` if the User role does not exist.

  ## Examples

      iex> get_user_role!(123)
      %UserRole{}

      iex> get_user_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_role!(id), do: Repo.get!(UserRole, id)

  @doc """
  Gets a single user_role with all associations preloaded.
  """
  def get_user_role_with_associations!(id) do
    UserRole
    |> Repo.get!(id)
    |> Repo.preload([:user, :group, :headquarters])
  end

  @doc """
  Creates a user_role.

  ## Examples

      iex> create_user_role(%{field: value})
      {:ok, %UserRole{}}

      iex> create_user_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_role(attrs \\ %{}) do
    %UserRole{}
    |> UserRole.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_role.

  ## Examples

      iex> update_user_role(user_role, %{field: new_value})
      {:ok, %UserRole{}}

      iex> update_user_role(user_role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_role(%UserRole{} = user_role, attrs) do
    user_role
    |> UserRole.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_role.

  ## Examples

      iex> delete_user_role(user_role)
      {:ok, %UserRole{}}

      iex> delete_user_role(user_role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_role(%UserRole{} = user_role) do
    Repo.delete(user_role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_role changes.

  ## Examples

      iex> change_user_role(user_role)
      %Ecto.Changeset{data: %UserRole{}}

  """
  def change_user_role(%UserRole{} = user_role, attrs \\ %{}) do
    UserRole.changeset(user_role, attrs)
  end

  @doc """
  Checks if a user can manage roles in a group.
  Only the group admin can manage roles.
  """
  def can_manage_roles?(user_id, group_id) do
    group = get_group!(group_id)
    group.admin_id == user_id
  end

  @doc """
  Checks if a user is a manager of a specific headquarters.
  Returns true if the user has an active role of "responsable_qg" for the headquarters.
  """
  def is_headquarters_manager?(user_id, headquarters_id) when is_integer(user_id) do
    UserRole
    |> where([ur], ur.user_id == ^user_id)
    |> where([ur], ur.headquarters_id == ^headquarters_id)
    |> where([ur], ur.role == "responsable_qg")
    |> where([ur], ur.active == true)
    |> Repo.exists?()
  end

  def is_headquarters_manager?(user_id, headquarters_id) when is_binary(headquarters_id) do
    case Integer.parse(headquarters_id) do
      {id, ""} -> is_headquarters_manager?(user_id, id)
      _ -> false
    end
  end

  @doc """
  Checks if a user is admin of a group.
  """
  def is_group_admin?(user_id, group_id) do
    group = get_group!(group_id)
    group.admin_id == user_id
  end

  @doc """
Returns a list of headquarters that have enough stock for the given product and quantity.
"""
def list_headquarters_with_stock(product_id, quantity) do
  from(h in Headquarters,
    join: s in Stock,
    on: s.headquarters_id == h.id,
    where: s.product_id == ^product_id and s.quantity >= ^quantity,
    select: h
  )
  |> Repo.all()
end
end
