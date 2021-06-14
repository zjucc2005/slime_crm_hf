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

  # POST /doctors/import_haodf
  def import_haodf
    @errors = []
    if request.post?
      begin
        sheet = open_spreadsheet(params[:file])
        raise 'excel表格里没有信息' if sheet.last_row < 2
        raise 'excel不能超过一百万行' if sheet.last_row > 1000000
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

end