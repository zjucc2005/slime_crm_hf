# frozen_string_literal: true

class CzbankController < ApplicationController

  def xibao
    start_date = (CzbankXibao.minimum(:trans_date) || Time.now).to_date
    end_date = Time.now.to_date
    @date_options = (start_date..end_date).map{|t| t.to_s}.reverse
  end

  def xibao_gen_pic
    options = {
        org_name: params[:org_name].to_s.strip,
        staff_name: params[:staff_name].to_s.strip,
        sale_value: "#{params[:sale_value]} 万",
        trans_date: (Date.parse(params[:trans_date]) rescue Time.now.to_date).strftime('%Y年%m月%d日')
    }
    @pic_path = CzbankXibao.draw_xibao_pic(options)
    redirect_to @pic_path.gsub(/^public/, '')
  end

  def xibao_create
    begin
      if params[:commit] == '生成喜报'
        redirect_to xibao_gen_pic_czbank_index_path(czbank_xibao_params)
      else
        @xibao = CzbankXibao.new(czbank_xibao_params)
        @xibao.save!
        flash[:success] = '操作成功'
        redirect_to xibao_czbank_index_path
      end
    rescue => e
      logger.info e.message
      flash[:danger] = '操作失败'
      redirect_to xibao_czbank_index_path
    end
  end

  def xibao_import
    begin
      sheet = open_spreadsheet(params[:file])
      raise 'excel表格里没有信息' if sheet.last_row < 2
      raise 'excel不能超过2000行' if sheet.last_row > 2000
      2.upto(sheet.last_row) do |i|
        parser = Utils::CzbankXibaoTemplateParser.new(sheet.row(i))
        unless parser.import
          raise "Row #{i}: #{parser.errors.join(', ')}"
        end
      end
      flash[:success] = '导入成功'
      redirect_to xibao_czbank_index_path
    rescue => e
      flash[:danger] = "导入失败: #{e.message}"
      redirect_to xibao_czbank_index_path
    end
  end

  def xibao_list
    if params[:trans_date].present?
      query = CzbankXibao.where(trans_date: params[:trans_date])
      @xibao_list = query.order(id: :desc)
      org_ranking_o = query.select('org_name, SUM(sale_value) AS sum_sale_value, SUM(bill_count) AS sum_bill_count').group(:org_name).order(sum_sale_value: :desc)
      @org_ranking = org_ranking_o.map{ |item| [item.org_name, item.sum_sale_value, item.sum_bill_count] }
      CzbankXibao::ORG_LIST.each do |org_name|
        if @org_ranking.select{|item| item[0] == org_name }[0].nil?
          @org_ranking << [org_name, 0, 0]
        end
      end
    else
      query = CzbankXibao.all
      @xibao_list = query.order(id: :desc)
    end

    respond_to { |f| f.js }
  end

  private
  def czbank_xibao_params
    params.require(:czbank_xibao).permit(:org_name, :staff_name, :sale_value, :trans_date, :bill_count)
  end
end