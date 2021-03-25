# encoding: utf-8
class CallRecordsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!


  # GET /call_records
  def index
    query = current_user.admin? ? CallRecord.all : CallRecord.where(operator_id: current_user.id)
    query = user_channel_filter(query)
    query = query.where('created_at >= ?', params[:created_at_ge]) if params[:created_at_ge].present?
    query = query.where('created_at <= ?', params[:created_at_le]) if params[:created_at_le].present?
    %w[name phone company title].each do |field|
      query = query.where("#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
    end
    %w[status project_id candidate_id].each do |field|
      query = query.where(field.to_sym => params[field]) if params[field].present?
    end

    @call_records = query.order(:updated_at => :desc).paginate(:page => params[:page], :per_page => 100)
  end

  # GET /call_records/:id
  # def show
  #   load_call_record
  # end

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
    @call_record = CallRecord.new(call_record_params.merge(created_by: current_user.id))
    if @call_record.save
      flash[:success] = t(:operation_succeeded)
      redirect_with_return_to call_records_path
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

    if @call_record.update(call_record_params)
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

  # GET /call_records/:id/edit_operator
  def edit_operator
    load_call_record
  end

  # PUT /call_records/:id/update_operator
  def update_operator
    load_call_record

    if @call_record.update(call_record_params)
      flash[:success] = t(:operation_succeeded)
      redirect_to call_records_path
    else
      render :edit_operator
    end
  end

  # PUT /call_records/:id/after_call?status=pending
  def after_call
    load_call_record

    ActiveRecord::Base.transaction do
      @call_record.number_of_calls += 1
      if params[:status] == 'accept_and_add_to_candidate'
        @call_record.status = 'accepted'
      else
        @call_record.status = params[:status]
      end
      @call_record.save!

      project_candidate = @call_record.project_candidate
      project_candidate.update_mark_by_call_record_status(@call_record.status) if project_candidate  # 同步更新项目内专家标识
    end

    if params[:status] == 'accept_and_add_to_candidate'
      first_name, last_name = Candidate.name_split(@call_record.name.strip)
      phone = @call_record.phone.strip
      redirect_to new_candidate_path(first_name: first_name, last_name: last_name, phone: phone)
    else
      flash[:success] = t(:operation_succeeded)
      redirect_to call_records_path
    end
  end

  # GET /call_records/:id/add_to_candidate
  def add_to_candidate
    load_call_record
    first_name, last_name = Candidate.name_split(@call_record.name.strip)
    phone = @call_record.phone.strip
    redirect_to new_candidate_path(first_name: first_name, last_name: last_name, phone: phone)
  end

  # POST /call_records/batch_import
  def batch_import
    @errors = []
    if request.post?
      begin
        sheet = open_spreadsheet(params[:file])
        @errors << 'excel表格里没有信息' if sheet.last_row < 2
        @errors << 'excel不能超过10000行' if sheet.last_row > 10000
        2.upto(sheet.last_row) do |i|
          parser = Utils::CallRecordTemplateParser.new(sheet.row(i), current_user.id)
          @errors << "Row #{i}: #{parser.errors.join(', ')}" unless parser.import
        end
      rescue Exception => e
        @errors << e.message
      end

      if @errors.blank?
        flash[:success] = t(:operation_succeeded)
        redirect_to call_records_path
      else
        render :batch_import
      end
    end
  end

  private
  def call_record_params
    params.require(:call_record).permit(:name, :phone, :company, :title, :status, :memo, :project_id, :candidate_id, :operator_id)
  end

  def load_call_record
    @call_record = CallRecord.find(params[:id])
    raise t(:not_authorized) unless @call_record.can_be_edited_by(current_user)
  end

end