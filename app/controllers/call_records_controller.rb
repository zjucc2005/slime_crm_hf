# encoding: utf-8
class CallRecordsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!


  # GET /call_records
  def index
    query = CallRecord.all
    query = user_channel_filter(query)
    query = query.where('created_at >= ?', params[:created_at_ge]) if params[:created_at_ge].present?
    query = query.where('created_at <= ?', params[:created_at_le]) if params[:created_at_le].present?
    %w[name phone company title].each do |field|
      query = query.where("#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
    end
    %w[status project_id candidate_id].each do |field|
      query = query.where(field.to_sym => params[field]) if params[field].present?
    end

    @call_records = query.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 20)
  end

  # GET /call_records/:id
  def show
    load_call_record
  end

  # GET /call_records/new
  def new
    @project = Project.where(id: params[:project_id]).first
    @candidate = Candidate.where(id: params[:candidate_id]).first
    related_params = {}
    related_params.merge!(project_id: @project.id) if @project
    if @candidate
      related_params.merge!(candidate_id: @candidate.id, name: @candidate.name, phone: @candidate.phone)
      exp = @candidate.latest_work_experience
      related_params.merge!(company: exp.org_cn, title: exp.title) if exp
    end
    @call_record = CallRecord.new(related_params)
  end

  # POST /call_records
  def create
    @call_record = CallRecord.new(call_record_params.merge(operator_id: current_user.id))
    if @call_record.save
      flash[:success] = t(:operation_succeeded)
      redirect_to call_records_path
    else
      render :new
    end
  end

  # GET /call_records/:id/edit
  def edit
    load_call_record
  end

  # PUT /call_records/:id
  def update
    load_call_record

    if @call_record.update(call_record_params.merge(operator_id: current_user.id))
      flash[:success] = t(:operation_succeeded)
      redirect_to call_records_path
    else
      render :edit
    end
  end

  # DELETE /call_records/:id
  def destroy
    load_call_record

    if @call_record.destroy
      flash[:success] = t(:operation_succeeded)
    else
      flash[:error] = t(:operation_failed)
    end
    redirect_to call_records_path
  end

  # PUT /call_records/:id/after_call?status=pending
  def after_call
    load_call_record

    ActiveRecord::Base.transaction do
      @call_record.number_of_calls += 1
      @call_record.status = params[:status]
      @call_record.operator_id = current_user.id
      @call_record.save!

      project_candidate = @call_record.project_candidate
      project_candidate.update_mark_by_call_record_status(@call_record.status) if project_candidate  # 同步更新项目内专家标识
    end

    flash[:success] = t(:operation_succeeded)
    redirect_to call_records_path
  end

  private
  def call_record_params
    params.require(:call_record).permit(:name, :phone, :company, :title, :memo, :project_id, :candidate_id)
  end

  def load_call_record
    @call_record = CallRecord.find(params[:id])
  end

end