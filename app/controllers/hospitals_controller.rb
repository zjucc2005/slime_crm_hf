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

end