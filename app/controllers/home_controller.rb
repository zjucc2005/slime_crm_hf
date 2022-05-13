# encoding: utf-8
class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.is_role?('su', 'admin', 'finance')
      load_dashboard_of_admin
    elsif current_user.is_role?('pm')
      load_dashboard_of_pm
    elsif current_user.is_role?('pa')
      load_dashboard_of_pa
    end
  end

  def css_demo
    arr = [2,3,5]
    arr.inject(:*)
  end

  private
  def load_dashboard_of_admin
    @total_experts              = user_channel_filter(Candidate.where(category: %w[expert doctor])).count
    @total_signed_companies     = user_channel_filter(Company.signed).count
    @total_tasks                = user_channel_filter(ProjectTask.where(status: 'finished')).count
    @total_charge_duration_hour = ( user_channel_filter(ProjectTask.where(status: 'finished')).sum(:charge_duration) / 60.0).round(1)
  end

  def load_dashboard_of_pm
    @total_experts              = Candidate.where(category: %w[expert doctor]).where(created_by: current_user.id).count
    @total_tasks                = ProjectTask.where(status: 'finished', created_by: current_user.id).count
    @total_charge_duration_hour = (ProjectTask.where(status: 'finished', created_by: current_user.id).sum(:charge_duration) / 60.0).round(1)
    @self_hour_monthly = (ProjectTask.where(status: 'finished', created_by: current_user.id, pm_id: current_user.id).where('started_at >= ?', current_month).sum(:charge_duration) / 60.0).round(1)
    @manage_hour_monthly = (ProjectTask.where(status: 'finished', pm_id: current_user.id).where.not(created_by: current_user.id).where('started_at >= ?', current_month).sum(:charge_duration) / 60.0).round(1)

    query = ProjectTask.where('created_by = :uid OR pm_id = :uid', uid: current_user.id)
    @project_tasks = query.order(status: :desc, started_at: :desc).paginate(page: params[:page], per_page: 50)
  end

  def load_dashboard_of_pa
    @total_experts              = Candidate.where(category: %w[expert doctor]).where(created_by: current_user.id).count
    @total_tasks                = ProjectTask.where(status: 'finished', created_by: current_user.id).count
    @total_charge_duration_hour = (ProjectTask.where(status: 'finished', created_by: current_user.id).sum(:charge_duration) / 60.0).round(1)
    @self_hour_monthly = (ProjectTask.where(status: 'finished', created_by: current_user.id).where('started_at >= ?', current_month).sum(:charge_duration) / 60.0).round(1)

    query = ProjectTask.where('created_by = :uid OR pm_id = :uid', uid: current_user.id)
    @project_tasks = query.order(status: :desc, started_at: :desc).paginate(page: params[:page], per_page: 50)
  end

  def current_month
    Time.now.beginning_of_month
  end
end