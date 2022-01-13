# encoding: utf-8
class CompaniesController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  # GET /companies
  def index
    query = user_channel_filter(Company.all)
    query = query.where('companies.created_at >= ?', params[:created_at_ge]) if params[:created_at_ge].present?
    query = query.where('companies.created_at <= ?', params[:created_at_le]) if params[:created_at_le].present?
    query = query.where('UPPER(companies.name) LIKE UPPER(:name) OR UPPER(companies.name_abbr) LIKE UPPER(:name)', { :name => "%#{params[:name].strip}%" }) if params[:name].present?
    %w[city industry].each do |field|
      query = query.where("companies.#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
    end
    %w[id status user_channel_id].each do |field|
      query = query.where("companies.#{field}" => params[field]) if params[field].present?
    end
    if params[:is_signed] == 'true'
      query = query.signed
    elsif params[:is_signed] == 'false'
      query = query.not_signed
    end
    @companies = query.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 20)
  end

  # GET /companies/:id
  def show
    load_company
    load_contracts
    load_clients
  end

  # GET /companies/new
  def new
    @company = Company.client.new
  end

  # POST /companies
  def create
    begin
      @company = Company.new(company_params.merge(created_by: current_user.id, user_channel_id: current_user.user_channel_id))

      if @company.save
        flash[:success] = t(:operation_succeeded)
        redirect_to company_path(@company)
      else
        render :new
      end
    rescue Exception => e
      flash.now[:error] = e.message
      render :new
    end
  end

  # GET /companies/:id/edit
  def edit
    load_company
  end

  # PUT /companies/:id
  def update
    begin
      load_company

      if @company.update(company_params)
        flash[:success] = t(:operation_succeeded)
        redirect_to company_path(@company)
      else
        render :edit
      end
    rescue Exception => e
      flash.now[:error] = e.message
      render :edit
    end
  end

  # GET /companies/:id/new_contract
  def new_contract
    load_company
    @contract = @company.contracts.new
  end

  # GET /companies/:id/new_client
  def new_client
    load_company
    @client = @company.candidates.client.new
  end

  # GET /companies/:id/load_client_options.js
  def load_client_options
    begin
      load_company
      load_clients
      @client_options = @clients.map{|client| [client.name, seat.id] }
    rescue
      @client_options = []
    end
    respond_to { |f| f.js }
  end

  # POST /companies/:id/import_client
  def import_client
    load_company
    @errors = []
    if request.post?
      begin
        sheet = open_spreadsheet(params[:file])
        raise 'excel表格里没有信息' if sheet.last_row < 2
        raise 'excel不能超过1000行' if sheet.last_row > 1000
        2.upto(sheet.last_row) do |i|
          parser = Utils::ClientTemplateParser.new(sheet.row(i), @company, current_user.id, current_user.user_channel_id)
          @errors << "Row #{i}: #{parser.errors.join(', ')}" unless parser.import
        end
      rescue Exception => e
        @errors << e.message
      end

      if @errors.blank?
        flash[:success] = t(:operation_succeeded)
        redirect_to company_path(@company)
      else
        render :import_client
      end
    end
  end

  private
  def load_company
    @company = Company.find(params[:id])
  end

  def load_contracts
    @contracts = @company.contracts
  end

  def load_clients
    @clients = @company.candidates
  end

  def company_params
    params.require(:company).permit(:name, :name_abbr, :tax_id, :industry, :city, :address, :linkman, :phone,
                                    :description, :compliance, :compliance_file, :project_task_notice_email)
  end

end