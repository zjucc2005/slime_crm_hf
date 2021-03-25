# encoding: utf-8
class ProjectRequirementsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  # GET /project_requirements
  def index
    query = ProjectRequirement.all
    query = query.where('created_at >= ?', params[:created_at_ge]) if params[:created_at_ge].present?
    query = query.where('created_at <= ?', params[:created_at_le]) if params[:created_at_le].present?
    %w[status project_id operator_id].each do |field|
      query = query.where(field.to_sym => params[field]) if params[field].present?
    end
    @project_requirements = query.order(:updated_at => :desc).paginate(:page => params[:page], :per_page => 20)
  end

  # GET /project_requirements/:id
  def show
    load_project_requirement
  end

  # GET /project_requirements/new
  def new
    @project_requirement = ProjectRequirement.new
  end

  # POST /project_requirements
  def create
    @project_requirement = ProjectRequirement.new(project_requirement_params.merge(created_by: current_user.id))

    if @project_requirement.save
      flash[:success] = t(:operation_succeeded)
      redirect_to project_requirements_path
    else
      render :new
    end
  end

  # GET /project_requirements/:id/edit
  def edit
    load_project_requirement
  end

  # PUT /project_requirements/:id
  def update
    begin
      load_project_requirement

      raise t(:not_authorized) unless @project_requirement.can_edit?

      if @project_requirement.update(project_requirement_params)
        flash[:success] = t(:operation_succeeded)
        redirect_to project_path(@project_requirement.project)
      else
        render :edit
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to root_path
    end
  end

  # PUT /project_requirements/:id/finish
  def finish
    begin
      load_project_requirement
      raise t(:not_authorized) unless @project_requirement.can_edit?
      @project_requirement.update!(status: 'finished')
      flash[:success] = t(:operation_succeeded)
    rescue Exception => e
      flash[:error] = e.message
    end
    redirect_to project_requirements_path
  end

  # PUT /project_requirements/:id/unfinish
  def unfinish
    begin
      load_project_requirement
      raise t(:not_authorized) unless @project_requirement.can_edit?
      @project_requirement.update!(status: 'unfinished')
      flash[:success] = t(:operation_succeeded)
    rescue Exception => e
      flash[:error] = e.message
    end
    redirect_to project_requirements_path
  end

  # PUT /project_requirements/:id/cancel
  def cancel
    begin
      load_project_requirement
      raise t(:not_authorized) unless @project_requirement.can_edit?
      @project_requirement.update!(status: 'cancelled')
      flash[:success] = t(:operation_succeeded)
    rescue Exception => e
      flash[:error] = e.message
    end
    redirect_to project_requirements_path
  end

  private
  def project_requirement_params
    params.require(:project_requirement).permit(:content, :demand_number, :file, :project_id, :operator_id)
  end

  def load_project_requirement
    @project_requirement = ProjectRequirement.find(params[:id])
  end

end