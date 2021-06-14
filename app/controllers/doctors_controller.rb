# encoding: utf-8
class DoctorsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  # GET /doctors
  def index
    set_per_page
    query = user_channel_filter(Candidate.doctor)
    @doctors = query.order(:created_at => :desc).paginate(:page => params[:page], :per_page => @per_page)
  end

  # GET /doctors/:id
  def show
    begin
      load_doctor
      # session_cache_show_history
    rescue Exception => e
      flash[:error] = e.message
      redirect_to doctors_path
    end
  end

  # GET /doctors/new
  def new
    @doctor = Candidate.doctor.new
  end

  # POST /doctors
  def create
    begin
      @doctor = Candidate.doctor.new(doctor_params.merge(created_by: current_user.id, user_channel_id: current_user.user_channel_id))
      if @doctor.valid?
        ActiveRecord::Base.transaction do
          @doctor.save!
          @doctor.experiences.work.create!(work_exp_params)
          unless @doctor.validates_presence_of_experiences
            raise t(:operation_failed)
          end
        end

        flash[:success] = t(:operation_succeeded)
        redirect_to doctor_path(@doctor)
      else
        flash.now[:error] = t(:operation_failed)
        render :new
      end
    rescue Exception => e
      flash.now[:error] = e.message
      render :new
    end
  end

  # GET /doctors/:id/edit
  def edit
    load_doctor
  end

  # PATCH /doctors/:id
  def update
    begin
      load_doctor

      ActiveRecord::Base.transaction do
        @doctor.update!(doctor_params)
        work_exp = @doctor.experiences.work.first
        work_exp ? work_exp.update!(work_exp_params) : @doctor.experiences.work.create!(work_exp_params)
        unless @doctor.validates_presence_of_experiences
          raise t(:operation_failed)
        end
      end

      flash[:success] = t(:operation_succeeded)
      redirect_to doctor_path(@doctor)
    rescue Exception => e
      flash[:error] = e.message
      render :edit
    end
  end

  # DELETE /doctors/:id
  def destroy
    begin
      load_doctor
      raise t(:cannot_delete) unless @doctor.can_delete?
      @doctor.destroy!
      flash[:success] = t(:operation_succeeded)
      redirect_with_return_to(doctors_path)
    rescue Exception => e
      logger.info "delete doctor failed: #{e.message}"
      flash[:error] = e.message
      redirect_with_return_to(doctors_path)
    end
  end

  # POST /doctors/import_haodf
  def import_haodf
    @errors = []
    if request.post?
      begin
        sheet = open_spreadsheet(params[:file])
        raise 'excel表格里没有信息' if sheet.last_row < 2
        raise 'excel不能超过一百万行' if sheet.last_row > 1000000
        sheet_head = %w[id province hospital department name url title educate_title expertise inquiry level]
        raise '表头不一致, 请检查数据文件' if sheet.row(1) != sheet_head  # 检查表头

        2.upto(sheet.last_row) do |i|
          parser = Utils::HaodfTemplateParser.new(sheet.row(i), current_user.id, current_user.user_channel_id)
          @errors << "Row #{i}: #{parser.errors.join(', ')}" unless parser.import
        end
      rescue Exception => e
        @errors << e.message
      end

      if @errors.blank?
        flash[:success] = t(:operation_succeeded)
        redirect_to doctors_path
      else
        render :import_haodf
      end
    end
  end

  private
  def load_doctor
    @doctor = Candidate.find(params[:id])
    current_user.access_candidate(@doctor)  # 访问次数统计/访问权限
  end

  def doctor_params
    params.require(:candidate).permit(:first_name, :last_name, :nickname, :city, :email, :email1, :phone, :phone1,
                                      :industry, :title, :company_id, :date_of_birth, :gender, :description,
                                      :is_available, :cpt, :currency, :recommender_id, :wechat, :cpt_face_to_face,
                                      :data_channel, :file, :inquiry, :expertise)
  end

  def work_exp_params
    params.require(:work_exp).permit(:org_cn, :department, :title, :description)
  end

end