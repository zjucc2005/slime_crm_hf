# encoding: utf-8
class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  # GET /users
  def index
    query = User.where(role: %w[admin pm pa finance])
    query = user_channel_filter(query)
    query = query.where('created_at >= ?', params[:created_at_ge]) if params[:created_at_ge].present?
    query = query.where('created_at <= ?', params[:created_at_le]) if params[:created_at_le].present?
    query = query.where('email ILIKE ?', "%#{params[:email].strip}%") if params[:email].present?
    query = query.where('name_cn ILIKE :name OR name_en ILIKE :name', { :name => "%#{params[:name].strip}%" }) if params[:name].present?
    %w[id role status user_channel_id].each do |field|
      query = query.where(field.to_sym => params[field]) if params[field].present?
    end
    @users = query.order(status: :asc, id: :asc).paginate(page: params[:page], per_page: 20)
  end

  # GET /users/:id
  def show
    load_user
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # POST /users, :create preserved for registration
  # POST /users/admin_create
  def admin_create
    begin
      @user = User.new(user_params.merge(user_channel_id: current_user.user_channel_id))

      raise "Invalid role[#{@user.role}]" unless @user.is_available_role?
      if @user.save
        flash[:success] = t(:operation_succeeded)
        redirect_to users_path
      else
        render :new
      end
    rescue Exception => e
      flash.now[:error] = e.message
      render :new
    end
  end

  # GET /users/:id/edit
  def edit
    load_user
    not_authorized_to_edit_admin
  end

  # PATCH /users/:id
  def update
    begin
      load_user

      raise t(:not_authorized) if @user.admin?
      raise "Invalid role[#{@user.role}]" unless @user.is_available_role?
      if @user.update(update_user_params)
        flash[:success] = t(:operation_succeeded)
        redirect_to user_path(@user)
      else
        render :edit
      end
    rescue Exception => e
      flash.now[:error] = e.message
      render :edit
    end
  end

  # GET/PUT /users/:id/edit_password
  def edit_password
    load_user
    not_authorized_to_edit_admin

    if request.put?
      begin
        if @user.update(params.permit(:password, :password_confirmation))
          flash[:success] = t('devise.passwords.updated_not_active')
          redirect_to user_path(@user)
        else
          raise @user.errors.full_messages.join(', ')
        end
      rescue Exception => e
        flash[:error] = e.message
        redirect_to edit_password_user_path(@user)
      end
    end
  end

  # GET /users/my_account
  def my_account
    @user = current_user
  end

  # GET/PUT /users/edit_my_account
  def edit_my_account
    @user = current_user

    if request.put?
      begin
        if @user.update(params.permit(:name_cn, :name_en, :phone, :date_of_birth))
          flash[:success] = t(:operation_succeeded)
        else
          raise @user.errors.full_messages.join(', ')
        end
        redirect_to my_account_users_path
      rescue Exception => e
        flash[:error] = e.message
        redirect_to edit_my_account_users_path
      end
    end
  end

  # GET/PUT /users/edit_my_password
  def edit_my_password
    @user = current_user

    if request.put?
      begin
        raise t(:invalid_current_password) unless @user.valid_password?(params[:current_password])
        if @user.update(params.permit(:password, :password_confirmation))
          flash[:success] = t('devise.passwords.updated_not_active')
          redirect_to my_account_users_path
        else
          raise @user.errors.full_messages.join(', ')
        end
      rescue Exception => e
        flash[:error] = e.message
        redirect_to edit_my_password_users_path
      end
    end
  end

  # GET/PUT /users/edit_my_user_channel
  def edit_my_user_channel
    if current_user.su?
      @user = current_user

      if request.put?
        if @user.update(user_channel_id: params[:user_channel_id])
          flash[:success] = t(:operation_succeeded)
        else
          flash[:error] = t(:operation_failed)
        end
        redirect_with_return_to(my_account_users_path)
      end
    else
      flash[:notice] = t(:not_authorized)
      redirect_to root_path
    end
  end

  def v_staff_options
    begin
      @users = user_channel_filter(User.active.where(role: %w[admin pm pa])).order(:id)
      render json: { status: 0, data: { users: @users.map{ |u| [u.uid_name, u.id] } } }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

  private
  def load_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :status, :title, :date_of_employment,
                                 :name_cn, :name_en, :phone, :date_of_birth, :candidate_access_limit)
  end

  def update_user_params
    params.require(:user).permit(:role, :status, :title, :date_of_employment, :date_of_resignation,
                                 :name_cn, :name_en, :phone, :date_of_birth, :candidate_access_limit)
  end

  def not_authorized_to_edit_admin
    if @user.admin? || @user.user_channel_id != current_user.user_channel_id
      flash[:notice] = t(:not_authorized)
      redirect_to root_path
    end
  end
end