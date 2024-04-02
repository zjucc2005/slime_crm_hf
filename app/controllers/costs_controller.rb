# frozen_string_literal: true

class CostsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  def index
    query = CostSummary.all
    @cost_summaries = query.order(datetime: :desc).paginate(page: params[:page], per_page: 20)
  end

  def v_summary_show
    begin
      @cost_summary = CostSummary.find(params[:cost_summary_id])
      render json: { status: 0, data: { cost_summary: @cost_summary.to_api } }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

  # req - { datetime: '2024-01-01', costs: [ { cost_type_id; 1, price: 8.8 } ] }
  # res - { status: 0, data: { cost_summary: {...} } }
  #       { status: 1, msg: 'error message' }
  def v_summary_new; end
  def v_summary_create
    begin
      if CostSummary.exists?(datetime: params[:datetime])
        raise "该月份已有成本结算数据，#{params[:datetime].to_time.strftime('%Y-%m')}"
      end
      ActiveRecord::Base.transaction do
        @cost_summary = CostSummary.create!(datetime: params[:datetime], operator_id: current_user.id)
        params[:costs].each do |k, item|
          cost_type  = CostType.find(item[:cost_type_id])
          @cost_summary.costs.create!(cost_type_id: cost_type.id, name: cost_type.name, price: item[:price])
        end
        @cost_summary.update_price!
      end
      render json: { status: 0, data: { cost_summary: @cost_summary.to_api } }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

  # req - { cost_summary_id: 1, datetime: '2024-01-01', costs: [ { cost_type_id; 1, price: 8.8 } ] }
  # res - { status: 0, data: { cost_summary: {...} } }
  #       { status: 1, msg: 'error message' }
  def v_summary_edit; end
  def v_summary_update
    begin
      @cost_summary = CostSummary.find(params[:cost_summary_id])
      if CostSummary.where.not(id: @cost_summary.id).exists?(datetime: params[:datetime])
        raise "该月份已有成本结算数据，#{params[:datetime].to_time.strftime('%Y-%m')}"
      end
      ActiveRecord::Base.transaction do
        @cost_summary.update(operator_id: current_user.id)
        params[:costs].each do |k, item|
          cost_type = CostType.find(item[:cost_type_id])
          cost = @cost_summary.costs.where(cost_type_id: cost_type.id).first
          if cost
            cost.update(price: item[:price])
          else
            @cost_summary.costs.create!(cost_type_id: cost_type.id, name: cost_type.name, price: item[:price])
          end
        end
        @cost_summary.update_price!
      end
      render json: { status: 0, data: { cost_summary: @cost_summary.to_api } }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

  def v_types; end
  def v_load_types
    begin
      @cost_types = CostType.root.order(:id).map(&:to_api)
      render json: { status: 0, data: { cost_types: @cost_types } }
    rescue => e
      render json: { status: 1, msg: e.message }
    end
  end

  def summary_chart
    current_year = Time.now.year
    @year_options = ['无'] + (2024..current_year).to_a.reverse    # year options
    if ['无', '', nil].include?(params[:year])
      @year = nil
      @s_time = Time.now.beginning_of_month - 11.months # start time
    else
      @year = current_year  # statistical year
      @s_time = Time.local @year
    end
    @x_axis = I18n.locale == :zh_cn ?
      %w[1月 2月 3月 4月 5月 6月 7月 8月 9月 10月 11月 12月] : %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]


    # init result
    @result = []
    @result << { name: '总计', data: [] }
    CostType.root.order(:id).each do |type|
      @result << { name: type.name, data: [], stack: '总计' }
    end
    @x_axis = []

    12.times do |i|
      datetime = @s_time + i.month  # start time
      cost_summary = CostSummary.where(datetime: datetime).first
      if cost_summary
        @result.select{|r| r[:name] == '总计' }[0][:data] << cost_summary.price
        cost_summary.price_group_by_root_type.each do |type|
          @result.select{|r| r[:name] == type[:name]}[0][:data] << type[:price] 
        end
      else
        @result.each do |item|
          item[:data] << 0.0  # 无数据时，用0占空位
        end
      end
      @x_axis << datetime.strftime('%Y.%m')
    end
  end
end