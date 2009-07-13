# Adding simple authentication using brilliant Authlogic
gem 'authlogic'

# Adding User model
generate(:model, 'user', 'email:string', 'crypted_password:string', 'password_salt:string', 'persistence_token:string')

file 'app/models/user.rb', <<-FILE
class User < ActiveRecord::Base
  acts_as_authentic
end
FILE

# Adding authentication lib
file 'lib/authentication.rb', <<-FILE
module Authentication
  def self.included(controller)
    controller.send :include, InstanceMethods
    controller.send :helper_method, :current_user_session, :current_user, :logged_in?, :current_user?
  end

  module InstanceMethods
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end

    def current_user?(user)
      logged_in? && user == current_user
    end

    def logged_in?
      current_user_session.present?
    end

    def require_user
      unless current_user
        store_location
        flash_message(:error, 'user_sessions.messages.must_be_logged_in')
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash_message(:error, 'user_sessions.messages.must_be_logged_out')
        redirect_to account_url
        return false
      end
    end

    def store_location(location = nil, rewrite = true)
      location ||= request.request_uri
      session[:return_to] = location if session[:return_to].nil? || rewrite
    end

    def redirect_back_or_default(default = '/')
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
  end
end
FILE

# Including Authentication in our Application
gsub_file 'app/controllers/application_controller.rb', /(class ApplicationController.*)/, "\\1\n  include Authentication"

# Adding Users controller
file 'app/controllers/users_controller.rb', <<-FILE
class UsersController < ApplicationController
  # Comment the 3 following lines to disable new user registration
  skip_before_filter :require_user # Override application wide filter
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash_message(:notice, :created)
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash_message(:notice, :updated)
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
FILE

# /users
file 'app/views/users/index.html.haml', <<-FILE
%h1= page_title

%ul.b_list.b_list-users= render @users
FILE

# /signup
file 'app/views/users/new.html.haml', <<-FILE
%h1= page_title

- form_for @user do |f|
  = f.error_messages
  .b_input
    = f.label :email
    = f.text_field :email
  .b_input
    = f.label :password
    = f.password_field :password
  .b_input
    = f.label :password_confirmation
    = f.password_field :password_confirmation
  .b_submit= submit(f)
FILE

# /account/edit
file 'app/views/users/edit.haml', <<-FILE
%h1= page_title

- form_for @user do |f|
  = f.error_messages
  // Put fields for editing here
  .b_submit= submit(f)
FILE

# Adding Users’ sessions
generate(:session, 'user_session')
generate(:controller, 'user_sessions')

# setup UsesSessionsController
file "app/controllers/user_sessions_controller.rb", <<-FILE
class UserSessionsController < ApplicationController
  skip_before_filter :require_user # Override application wide filter
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash_message(:notice, :created)
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash_message(:notice, :destroyed)
    redirect_back_or_default new_user_session_url
  end
end
FILE

# /signin
file 'app/views/user_sessions/new.haml', <<-FILE
%h1= page_title

- form_for @user_session do |f|
  = f.error_messages
  .b_input
    = f.label :email
    = f.text_field :email
  .b_input
    = f.label :password
    = f.password_field :password
  .b_submit= submit(f)
FILE

# Adding routes
["map.signin    'signin', :controller => 'user_sessions', :action => 'new'",
 "map.signout   'signout', :controller => 'user_sessions', :action => 'destroy'",
 "map.signup    'signup', :controller => 'users', :action => 'new'",
 "map.resource  :user_sessions",
 "map.resource  :account, :controller => 'users'",
 "map.resources :users",
].each do |r|
  route(r)
end

git :add => '.'
git :commit => '-am "Added AuthLogic authentication"'

# run migrations
rake 'db:migrate'
