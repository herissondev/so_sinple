defmodule SoSinpleWeb.UserAuth do
  use SoSinpleWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias SoSinple.Accounts
  alias SoSinple.Organizations

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_so_sinple_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      SoSinpleWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule SoSinpleWeb.PageLive do
        use SoSinpleWeb, :live_view

        on_mount {SoSinpleWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{SoSinpleWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:check_group_access, %{"group_id" => group_id}, _session, socket) do
    if can_access_group?(socket.assigns.current_user, group_id) do
      group = Organizations.get_group!(group_id)
      {:cont, Phoenix.Component.assign(socket, :current_group, group)}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You don't have access to this group.")
        |> Phoenix.LiveView.redirect(to: ~p"/groups")

      {:halt, socket}
    end
  end

  def on_mount(:check_group_access, _params, _session, socket) do
    socket =
      socket
      |> Phoenix.LiveView.put_flash(:error, "Group not specified.")
      |> Phoenix.LiveView.redirect(to: ~p"/groups")

    {:halt, socket}
  end

  @doc """
  Vérifie si l'utilisateur a accès au QG spécifié.
  L'utilisateur doit avoir un rôle dans le groupe auquel appartient le QG.
  """
  def on_mount(:check_headquarters_access, %{"group_id" => group_id, "headquarters_id" => headquarters_id}, _session, socket) do
    if can_access_group?(socket.assigns.current_user, group_id) do
      group = Organizations.get_group!(group_id)
      headquarters = Organizations.get_headquarters!(headquarters_id)

      if headquarters.group_id == String.to_integer(group_id) do
        {:cont,
         socket
         |> Phoenix.Component.assign(:current_group, group)
         |> Phoenix.Component.assign(:current_headquarters, headquarters)}
      else
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "This headquarters does not belong to the specified group.")
          |> Phoenix.LiveView.redirect(to: ~p"/groups/#{group_id}/headquarters")

        {:halt, socket}
      end
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You don't have access to this group.")
        |> Phoenix.LiveView.redirect(to: ~p"/groups")

      {:halt, socket}
    end
  end

  @doc """
  Vérifie si l'utilisateur peut gérer les rôles utilisateurs dans un groupe.
  Seul l'administrateur du groupe peut gérer les rôles.
  """
  def on_mount(:check_user_roles_access, %{"group_id" => group_id}, _session, socket) do
    if can_access_group?(socket.assigns.current_user, group_id) do
      group = Organizations.get_group!(group_id)
      can_manage = Organizations.can_manage_roles?(socket.assigns.current_user.id, group_id)

      {:cont,
       socket
       |> Phoenix.Component.assign(:current_group, group)
       |> Phoenix.Component.assign(:can_manage_roles, can_manage)}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You don't have access to this group.")
        |> Phoenix.LiveView.redirect(to: ~p"/groups")

      {:halt, socket}
    end
  end

  @doc """
  Vérifie si l'utilisateur peut accéder à un rôle utilisateur spécifique.
  L'utilisateur doit être l'administrateur du groupe auquel appartient le rôle.
  """
  def on_mount(:check_user_role_access, %{"group_id" => group_id, "user_role_id" => user_role_id}, _session, socket) do
    if can_access_group?(socket.assigns.current_user, group_id) do
      group = Organizations.get_group!(group_id)
      user_role = Organizations.get_user_role!(user_role_id)

      if user_role.group_id == String.to_integer(group_id) do
        can_manage = Organizations.can_manage_roles?(socket.assigns.current_user.id, group_id)

        {:cont,
         socket
         |> Phoenix.Component.assign(:current_group, group)
         |> Phoenix.Component.assign(:current_user_role, user_role)
         |> Phoenix.Component.assign(:can_manage_roles, can_manage)}
      else
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "This user role does not belong to the specified group.")
          |> Phoenix.LiveView.redirect(to: ~p"/groups/#{group_id}/user_roles")

        {:halt, socket}
      end
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You don't have access to this group.")
        |> Phoenix.LiveView.redirect(to: ~p"/groups")

      {:halt, socket}
    end
  end

  defp can_access_group?(user, group_id) do
    group_id = if is_binary(group_id), do: String.to_integer(group_id), else: group_id

    group = Organizations.get_group!(group_id)
    is_admin = group.admin_id == user.id

    has_role = Organizations.list_user_roles_by_user(user.id)
               |> Enum.any?(fn role -> role.group_id == group_id && role.active end)

    is_admin || has_role
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
