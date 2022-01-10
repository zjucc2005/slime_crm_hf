# frozen_string_literal: true
#
class ClientsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  def index
    query = user_channel_filter(Candidate.client)
    query = query.where('candidates.name ~* :name OR candidates.nickname ~* :name', { name: params[:name].strip }) if params[:name].present?
    %w[title phone email].each do |field|
      query = query.where("candidates.#{field} ~* ?", params[field].strip.shellescape) if params[field].present?
    end
    if params[:company].present?
      query = query.joins(:company).where('companies.name ILIKE :company OR companies.name_abbr ILIKE :company', { company: "%#{params[:company].strip}%" })
    end
    if params[:client_active] == 'true'
      query = query.joins(:project_candidates).where('project_candidates.category': 'client').where('project_candidates.created_at > ?', Time.now - 3.months).distinct
    end
    @clients = query.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end

end