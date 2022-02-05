# encoding: utf-8
class HospitalsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  def index
    query = Hospital.all
    %w[name].each do |field|
      query = query.where("#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
    end
    if params[:ld_province_id].present?
      @province = LocationDatum.where(id: params[:ld_province_id]).first
      if @province && params[:ld_city_id].present?
        @city = @province.direct_children.where(id: params[:ld_city_id]).first
      end
    end
    query = query.where(province: @province.name) if @province
    query = query.where(city: @city.name) if @city
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
    @hospital.departments.each do |dep|
      count = Candidate.doctor.joins(:experiences).where('candidate_experiences.org_id': @hospital.id, 'candidate_experiences.dep_id': dep.id).count
      @data << { id: dep.id, name: dep.name, count: count }
    end
  end

  # GET, format.json
  def load_departments
    load_hospital
    @data = []
    @hospital.departments.each do |dep|
      count = Candidate.doctor.joins(:experiences).where('candidate_experiences.org_id': @hospital.id, 'candidate_experiences.dep_id': dep.id).count
      @data << { id: dep.id, name: dep.name, count: count }
    end
    render :json => @data.to_json
  end

  # GET, js
  def change_hospital_for_doctor_form
    load_hospital
    @city = "#{@hospital.province} #{@hospital.city}"
    @department_options = '<option>Please select</option>' +
        @hospital.departments.map { |dep| "<option value=\"#{dep.id}\">#{dep.name}</option>" }.join
    respond_to { |f| f.js }
  end

  # def load_hospital_options
  #   @hospital_options = '<option value>Please select</option>'
  #   @hospital_options += Hospital.all.order(created_at: :asc).map { |hos| "<option value=\"#{hos.id}\">#{hos.name}</option>" }.join
  #   respond_to { |f| f.js }
  # end

  # GET, json
  def hospital_options
    query = Hospital.all
    query = query.where('name ILIKE ?', "%#{params[:name].strip}%") if params[:name].present?
    @data = query.order(id: :asc).limit(100).map { |item| { id: item.id, name: item.name } }
    render json: @data.to_json
  end

  # GET, js
  def load_children
    load_hospital
    @hospital_departments = @hospital.departments
    @hospital_department_options = '<option value>Please select</option>'
    @hospital_department_options += @hospital.departments.map { |dep| "<option value=\"#{dep.id}\">#{dep.name}</option>" }.join
    if params[:hospital_department_id].present? && @hospital.departments.exists?(id: params[:hospital_department_id])
      @hospital_department_id = params[:hospital_department_id]
    end
    respond_to { |f| f.js }
  end

  private
  def load_hospital
    @hospital = Hospital.find(params[:id])
  end

end