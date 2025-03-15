defmodule SoSinpleWeb.Router do
  use SoSinpleWeb, :router

  import SoSinpleWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoSinpleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SoSinpleWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", SoSinpleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:so_sinple, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SoSinpleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SoSinpleWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SoSinpleWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", SoSinpleWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SoSinpleWeb.UserAuth, :ensure_authenticated}, {SoSinpleWeb.UserAuth, :mount_current_user}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end

    live_session :default,
      on_mount: [{SoSinpleWeb.UserAuth, :ensure_authenticated},
                 {SoSinpleWeb.UserAuth, :mount_current_user}] do
      live "/groups", GroupLive.Index, :index
      live "/groups/new", GroupLive.New, :new
    end

    # Routes pour un groupe spécifique
    live_session :group_access,
      on_mount: [{SoSinpleWeb.UserAuth, :ensure_authenticated},
                 {SoSinpleWeb.UserAuth, :mount_current_user},
                 {SoSinpleWeb.UserAuth, :check_group_access}],
      layout: {SoSinpleWeb.Layouts, :dashboard} do
      live "/groups/:group_id", GroupLive.Show, :show
      live "/groups/:group_id/edit", GroupLive.Edit, :edit

      # Liste des QG d'un groupe
      live "/groups/:group_id/headquarters", HeadquartersLive.Index, :index
      live "/groups/:group_id/headquarters/new", HeadquartersLive.New, :new
      live "/groups/:group_id/headquarters/:headquarter_id/edit", HeadquartersLive.Edit, :edit

      # Liste des items d'un groupe
      live "/groups/:group_id/items", ItemLive.Index, :index
      live "/groups/:group_id/items/new", ItemLive.New, :new
      live "/groups/:group_id/items/:id/edit", ItemLive.Edit, :edit
      live "/groups/:group_id/items/:item_id", ItemLive.Show, :show

      # Routes pour les rôles utilisateurs d'un groupe
      live "/groups/:group_id/user_roles", UserRoleLive.Index, :index
      live "/groups/:group_id/user_roles/new", UserRoleLive.New, :new
      live "/groups/:group_id/user_roles/:user_role_id/edit", UserRoleLive.Edit, :edit
      live "/groups/:group_id/user_roles/:user_role_id", UserRoleLive.Show, :show
    end

    # Routes pour un QG spécifique
    live_session :headquarters_access,
      on_mount: [{SoSinpleWeb.UserAuth, :ensure_authenticated},
                 {SoSinpleWeb.UserAuth, :mount_current_user},
                 {SoSinpleWeb.UserAuth, :check_headquarters_access}],
      layout: {SoSinpleWeb.Layouts, :dashboard} do
      live "/groups/:group_id/headquarters/:headquarter_id", HeadquartersLive.Show, :show

      # Liste des stocks d'un QG
      live "/groups/:group_id/headquarters/:headquarter_id/stock_items", StockItemLive.Index, :index
      live "/groups/:group_id/headquarters/:headquarter_id/stock_items/new", StockItemLive.New, :new
      live "/groups/:group_id/headquarters/:headquarter_id/stock_items/:stock_item_id/edit", StockItemLive.Edit, :edit
      live "/groups/:group_id/headquarters/:headquarter_id/stock_items/:stock_item_id", StockItemLive.Show, :show

      # Gestion des commandes d'un QG
      live "/groups/:group_id/headquarters/:headquarter_id/orders", OrderLive.Index, :index
      live "/groups/:group_id/headquarters/:headquarter_id/orders/new", OrderLive.New, :new
      live "/groups/:group_id/headquarters/:headquarter_id/orders/:id/edit", OrderLive.Edit, :edit
      live "/groups/:group_id/headquarters/:headquarter_id/orders/:id", OrderLive.Show, :show
    end

    # Routes pour les livreurs
    live_session :delivery_person_access,
      on_mount: [{SoSinpleWeb.UserAuth, :ensure_authenticated},
                 {SoSinpleWeb.UserAuth, :mount_current_user},
                 {SoSinpleWeb.UserAuth, :check_group_access},
                 {SoSinpleWeb.UserAuth, :check_delivery_person_access}],
      layout: {SoSinpleWeb.Layouts, :dashboard} do
      live "/groups/:group_id/delivery", DeliveryLive.Index, :index
      live "/groups/:group_id/delivery/orders/:id", DeliveryLive.Show, :show
    end
  end

  scope "/", SoSinpleWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{SoSinpleWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
