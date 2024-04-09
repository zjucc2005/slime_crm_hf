# frozen_string_literal: true

class KpiSummariesController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  def index
  end

  # req - { datetime: '2024-01-01', user_id: 1, infos: [ { name: '访谈小时', price: 8.8 } ] }
  # res - { status: 0, data: { kpi_summary: {...} } }
  #       { status: 1, msg: 'error message' }


  def v_summary_show
    begin
      @kpi_summary = KpiSummary.find(params[:kpi_summary_id])
      render json: { status: 0, data: { kpi_summary: @kpi_summary.to_api } }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

  def v_summary_init
    begin
      raise 'datetime is required' if params[:datetime].blank?
      raise '请选择历史月份' if params[:datetime].to_time >= Time.now.beginning_of_month
      raise 'user_id is required' if params[:user_id].blank?
      @kpi_summary = KpiSummary.where(datetime: params[:datetime], user_id: params[:user_id]).first
      if @kpi_summary
        @data = @kpi_summary.to_init_data
      else
        @data = KpiSummary.init_data(params[:datetime], params[:user_id])
      end
      render json: { status: 0, data: @data }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

end