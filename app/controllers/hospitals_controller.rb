# encoding: utf-8
class HospitalsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  def index
    query = Hospital.all
    %w[name province].each do |field|
      query = query.where("#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
    end
    if params[:level].present?
      level = case params[:level].strip
                when '三级' then %w[三级 三甲 三乙 三丙]
                when '二级' then %w[二级 二甲 二乙 二丙]
                when '一级' then %w[一级 一甲 一乙 一丙]
                else params[:level].strip
              end
      query = query.where(level: level)
    end
    @hospitals = query.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 50)
  end

  def show
    load_hospital

    @data = []
    @hospital.departments.each do |dept|
      count = Candidate.doctor.joins(:experiences).
        where('candidate_experiences.org_cn = ? AND candidate_experiences.department = ?', @hospital.name, dept.name).count
      @data << { name: dept.name, count: count }
    end
  end

  # GET, format.json
  def load_departments
    load_hospital
    @data = []
    @hospital.departments.each do |dept|
      count = Candidate.doctor.joins(:experiences).
        where('candidate_experiences.org_cn = ? AND candidate_experiences.department = ?', @hospital.name, dept.name).count
      @data << { name: dept.name, count: count }
    end
    render :json => @data.to_json
  end

  # GET
  def change_hospital_for_doctor_form
    load_hospital
    @city = "#{@hospital.province} #{@hospital.city}"
    @department_options = '<option>Please select</option>' +
        @hospital.departments.map { |dep| "<option value=\"#{dep.id}\">#{dep.name}</option>" }.join
    respond_to { |f| f.js }
  end

  private
  def load_hospital
    @hospital = Hospital.find(params[:id])
  end

end