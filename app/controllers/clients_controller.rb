# frozen_string_literal: true
#
class ClientsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  def index
    query = user_channel_filter(Candidate.client)
    query = query.where('candidates.name ~* :name OR candidates.nickname ~* :name', { name: params[:name].strip }) if params[:name].present?
    query = query.where('candidates.phone ~* :phone OR candidates.phone1 ~* :phone', { :phone => params[:phone].strip.shellescape }) if params[:phone].present?
    %w[title email].each do |field|
      query = query.where("candidates.#{field} ~* ?", params[field].strip.shellescape) if params[field].present?
    end
    %w[company_id job_status].each do |field|
      query = query.where(field.to_sym => params[field].strip) if params[field].present?
    end
    if params[:client_active] == 'true'
      query = query.joins(:project_candidates).where('project_candidates.category': 'client').where('project_candidates.created_at > ?', Time.now - 3.months).distinct
    end
    @clients = query.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end

  def new
    @client = Candidate.client.new(company_id: params[:company_id])
  end

  def edit
    load_client
    @company = @client.company
  end

  private

  def load_client
    @client = Candidate.find(params[:id])
  end

end