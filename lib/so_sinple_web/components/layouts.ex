defmodule SoSinpleWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use SoSinpleWeb, :controller` and
  `use SoSinpleWeb, :live_view`.
  """
  use SoSinpleWeb, :html

  alias SoSinple.Organizations
  alias SoSinple.Repo
  import Ecto.Query

  embed_templates "layouts/*"

  @doc """
  Checks if a user has a specific role.
  """
  def has_role?(user, role) when not is_nil(user) do
    from(ur in Organizations.UserRole,
      where: ur.user_id == ^user.id and ur.role == ^role and ur.active == true,
      select: count(ur.id)
    )
    |> Repo.one()
    |> Kernel.>(0)
  end

  def has_role?(_user, _role), do: false
end
