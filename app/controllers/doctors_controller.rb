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

  # GET /doctor/:id
  def show
    begin
      load_doctor
      # session_cache_show_history
    rescue Exception => e
      flash[:error] = e.message
      redirect_to doctors_path
    end
  end

  private
  def load_doctor
    @doctor = Candidate.find(params[:id])
    current_user.access_candidate(@doctor)  # 访问次数统计/访问权限
  end

end