# encoding: utf-8
class StatisticsController < ApplicationController
  before_action :authenticate_user!
  # load_and_authorize_resource

  # GET /statistics/current_month_count_infos.js
  def current_month_count_infos
    current_month = Time.now.beginning_of_month
    project_task_query = ProjectTask.where(status: 'finished', currency: 'RMB').where('started_at >= ?', current_month)
    project_task_query = user_channel_filter(project_task_query)
    project_task_cost_query = ProjectTaskCost.joins(:project_task).where('project_tasks.status': 'finished', 'project_task_costs.currency': 'RMB').
      where('project_tasks.started_at >= ?', current_month).where('project_task_costs.category': 'expert')
    project_task_cost_query = user_channel_filter(project_task_cost_query)

    total_experts              = user_channel_filter(Candidate.where(category: %w[expert doctor]).where('created_at >= ?', current_month)).count
    total_tasks                = project_task_query.count
    total_charge_duration_hour = (project_task_query.sum(:charge_duration) / 60.0).round(1)
    total_income               = project_task_query.sum(:actual_price)
    total_income_unbilled      = project_task_query.where('project_tasks.charge_status' => 'unbilled').sum(:actual_price)
    total_income_billed        = project_task_query.where('project_tasks.charge_status' => 'billed').sum(:actual_price)
    total_expert_fee           = project_task_cost_query.sum('project_task_costs.price')
    total_expert_fee_unpaid    = project_task_cost_query.where('project_tasks.payment_status' => 'unpaid').sum('project_task_costs.price')
    if total_charge_duration_hour.zero?
      premium_charge_rate = 0
    else
      premium_charge_rate = project_task_query.where(expert_level: 'premium').sum(:charge_duration).to_f / project_task_query.sum(:charge_duration)
    end

    @current_month_count_infos = [
      { :name => t('dashboard.total_experts'),              :value => total_experts,              :url => v_monthly_new_statistics_path },
      { :name => t('dashboard.total_tasks'),                :value => total_tasks,                :url => v_monthly_new_statistics_path },
      { :name => t('dashboard.total_charge_duration_hour'), :value => total_charge_duration_hour, :url => v_monthly_new_statistics_path },
      { :name => t('dashboard.total_income'),               :value => total_income,               :url => finance_summary_statistics_path },
      { :name => t('dashboard.total_income_unbilled'),      :value => total_income_unbilled,      :url => nil },
      { :name => t('dashboard.total_income_billed'),        :value => total_income_billed,        :url => nil },
      { :name => t('dashboard.total_expert_fee'),           :value => total_expert_fee,           :url => finance_summary_statistics_path },
      { :name => t('dashboard.total_expert_fee_unpaid'),    :value => total_expert_fee_unpaid,    :url => nil },
      { name: t('dashboard.premium_charge_rate'), value: "#{(premium_charge_rate * 100).round(1)} %", url: nil }
    ]

    respond_to do |f|
      f.js
    end
  end

  # GET /statistics/current_month_task_ranking?limit=10
  def current_month_task_ranking
    # 最近三个月份
    current_month = Time.now.beginning_of_month
    @month_options = []
    12.times do |i|
      _month_ = current_month - i.month
      @month_options << [_month_.strftime('%Y-%m'), _month_.strftime('%F')]
    end

    s_month = (params[:month].to_time rescue nil) || current_month  # 统计月份
    result = []
    if current_user.admin?
      users = User.active.where(role: %w[admin pm pa])  # 激活中用户 + 角色admin/pm/pa
    else
      users = User.where(id: current_user.id)
    end
    users = user_channel_filter(users)
    project_tasks = ProjectTask.where(status: 'finished').where('started_at >= ? AND started_at < ?', s_month, s_month + 1.month)
    users.each do |user|
      if user.is_role?('admin', 'pm')
        interview_minutes = project_tasks.where(created_by: user.id).sum(:charge_duration)
        manage_minutes = project_tasks.where(pm_id: user.id).where.not(created_by: user.id).sum(:charge_duration)
        manage_minutes_group = project_tasks.where(pm_id: user.id).where.not(created_by: user.id).
                               select('created_by, sum(charge_duration) as charge_duration').group(:created_by)
        manage_minutes_detail = manage_minutes_group.map{ |item|
          { username: User.find(item.created_by)&.name_cn, interview_minutes: item.charge_duration }
        }
      else
        interview_minutes = project_tasks.where(created_by: user.id).sum(:charge_duration)
        manage_minutes = 0.0
        manage_minutes_detail = []
      end
      total_minutes = interview_minutes + manage_minutes
      if total_minutes > 0
        new_expert_count = project_tasks.where(created_by: user.id, is_new_expert: true).count
        new_expert_rate = new_expert_count.zero? ?
          0 : new_expert_count.to_f / project_tasks.where(created_by: user.id).count
        result << { 
          username: user.name_cn,
          interview_minutes: interview_minutes,
          manage_minutes: manage_minutes,
          manage_minutes_detail: manage_minutes_detail,
          total_minutes: total_minutes,
          new_expert_rate: new_expert_rate
        }
      end

      # pm_minutes = project_tasks.where(pm_id: user.id).sum(:charge_duration) * 0.5       # 权重 0.5
      # pa_minutes = project_tasks.where(created_by: user.id).sum(:charge_duration) * 0.5  # 权重 0.5
      # total_minutes = pm_minutes + pa_minutes
      # if total_minutes > 0
      #   result << { :username => user.name_cn, :pm_minutes => pm_minutes, :pa_minutes => pa_minutes, :total_minutes => total_minutes }
      # end
    end

    @current_month_task_ranking = result.sort_by{|e| e[:total_minutes]}.reverse
    respond_to do |f|
      f.js
      f.html
    end
  end

  # GET /statistics/unscheduled_projects.js
  # def unscheduled_projects
  #   query = Project.where(status: 'initialized').order(:created_at => :asc)
  #   query = user_channel_filter(query)
  #   query = query.limit(params[:limit]) if params[:limit].present?
  #   @projects = query
  #
  #   respond_to do |f|
  #     f.js
  #   end
  # end

  def wait_to_bill_projects
    company_ids = Contract.available.where(payment_way: 'by_project').pluck(:company_id)
    query = Project.joins(:project_tasks).where(
      'projects.company_id': company_ids, 
      'projects.status': 'ongoing', 
      'project_tasks.status': 'finished', 
      'project_tasks.charge_status': 'unbilled'
      ).where('projects.updated_at <= ?', Time.now - 60.days).distinct
    query = user_channel_filter(query, 'projects.user_channel_id')
    @count = query.count
    query = query.limit(params[:limit]) if params[:limit].present?
    @projects = query.order(:id)
  end

  # GET /statistics/ongoing_project_requirements.js
  def ongoing_project_requirements
    query = ProjectRequirement.joins(:project).where('project_requirements.status': 'ongoing').order(:created_at => :desc)
    query = user_channel_filter(query, 'projects.user_channel_id')
    query = query.limit(params[:limit]) if params[:limit].present?
    @project_requirements = query

    respond_to do |f|
      f.js
    end
  end

  # GET /statistics/ongoing_project_tasks
  def ongoing_project_tasks
    query = ProjectTask.where(status: 'ongoing').order(:started_at => :asc)
    query = user_channel_filter(query)
    @count = query.count
    query = query.limit(params[:limit]) if params[:limit].present?
    @project_tasks = query
  end

  # GET /statistics/finance_summary
  def finance_summary
    # current_year = Time.now.year
    # @year_options = (2020..current_year).to_a.reverse              # year options
    # @year = params[:year] || current_year                          # statistical year
    # @currency = params[:currency] || 'RMB'                         # currency
    # @user_channel_id = params[:user_channel_id] || current_user.user_channel_id  # user_channel_id
    # @company_id = params[:company_id]
    # @x_axis = I18n.locale == :zh_cn ?
    #   %w[1月 2月 3月 4月 5月 6月 7月 8月 9月 10月 11月 12月] : %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

    current_year = Time.now.year
    @year_options = ['无'] + (2020..current_year).to_a.reverse    # year options
    if ['无', '', nil].include?(params[:year])
      @year = nil
      o_time = Time.now.beginning_of_month - 11.months # start time
    else
      @year = params[:year] || current_year  # statistical year
      o_time = Time.local @year
    end
    @currency = params[:currency] || 'RMB'                         # currency
    @user_channel_id = params[:user_channel_id] || current_user.user_channel_id  # user_channel_id
    @company_id = params[:company_id]
    @x_axis = []
    # annual total infos
    income              = []
    expense             = []
    profit              = []
    expense_expert      = []
    expense_expert_tax  = []
    expense_recommend   = []
    expense_translation = []
    expense_others      = []

    if @company_id.present?
      project_task_query = ProjectTask.joins(:project).
        where('projects.company_id': @company_id, 'project_tasks.status': 'finished', 'project_tasks.currency': @currency)
      project_task_cost_query = ProjectTaskCost.joins(:project_task).joins('LEFT JOIN projects on projects.id = project_tasks.project_id').
        where('projects.company_id': @company_id, 'project_tasks.status': 'finished', 'project_task_costs.currency': @currency)
    else
      project_task_query = ProjectTask.where(status: 'finished', currency: @currency)
      project_task_cost_query = ProjectTaskCost.joins(:project_task).where('project_tasks.status': 'finished', 'project_task_costs.currency': @currency)
    end
    if @user_channel_id.present?
      project_task_query = project_task_query.where(user_channel_id: @user_channel_id)
      project_task_cost_query = project_task_cost_query.where(user_channel_id: @user_channel_id)
    end

    12.times do |i|
      s_time = o_time + i.month  # start time
      e_time = s_time + 1.month  # end time

      cost_group = project_task_cost_query.where('project_tasks.started_at BETWEEN ? AND ?', s_time, e_time).
        select('SUM(project_task_costs.price) AS sum_price, project_task_costs.category').group('project_task_costs.category')

      expert_fee      = cost_group.select{|c| c.category == 'expert' }[0].try(:sum_price)      || 0.0
      expert_tax_fee  = cost_group.select{|c| c.category == 'expert_tax' }[0].try(:sum_price)  || 0.0
      recommend_fee   = cost_group.select{|c| c.category == 'recommend' }[0].try(:sum_price)   || 0.0
      translation_fee = cost_group.select{|c| c.category == 'translation' }[0].try(:sum_price) || 0.0
      others_fee      = cost_group.select{|c| c.category == 'others' }[0].try(:sum_price)      || 0.0
      total_in = project_task_query.where('project_tasks.started_at BETWEEN ? AND ?', s_time, e_time).sum(:actual_price)
      total_ex = expert_fee + expert_tax_fee + recommend_fee + translation_fee + others_fee

      income << total_in
      expense << total_ex
      profit << total_in - total_ex
      expense_expert << expert_fee
      expense_expert_tax << expert_tax_fee
      expense_recommend << recommend_fee
      expense_translation << translation_fee
      expense_others << others_fee
      @x_axis << s_time.strftime('%Y.%m')
    end


    @result = [
      { name: t('dashboard.total_income'), data: income },
      { name: t('dashboard.expense'), data: expense },
      { name: t('dashboard.profit'), data: profit }
      # { :name => t('dashboard.expense_expert'), :data => expense_expert, :stack => t('dashboard.expense') },
      # { :name => t('dashboard.expense_recommend'), :data => expense_recommend, :stack => t('dashboard.expense') },
      # { :name => t('dashboard.expense_translation'), :data => expense_translation, :stack => t('dashboard.expense') },
      # { :name => t('dashboard.expense_others'), :data => expense_others, :stack => t('dashboard.expense') },
    ]

    @annual_count_infos = [
      { name: t('dashboard.total_income'), value: income.sum },
      { name: t('dashboard.expense'), value: expense.sum },
      { name: t('dashboard.expense_expert'), value: expense_expert.sum },
      { name: '税费（专家费用）', value: expense_expert_tax.sum },
      { name: t('dashboard.expense_recommend'), value: expense_recommend.sum },
      { name: t('dashboard.expense_translation'), value: expense_translation.sum },
      { name: t('dashboard.expense_others'), value: expense_others.sum }
    ]
  end

  def v_monthly_new
    if params[:datetime]
      begin
        @year = (params[:datetime]&.to_time || Time.now).beginning_of_year
        @data = []
        12.times do |i|
          s_time = @year + i.month
          q_experts = user_channel_filter(Candidate.where(category: %w[expert doctor]).where('created_at BETWEEN ? AND ?', s_time, s_time + 1.month))
          q_tasks = user_channel_filter(ProjectTask.where(status: 'finished', currency: 'RMB').where('started_at BETWEEN ? AND ?', s_time, s_time + 1.month))

          @data << {
            name: s_time.strftime('%Y.%m'),
            new_expert: q_experts.count,
            new_task: q_tasks.count,
            new_task_duration: (q_tasks.sum(:charge_duration) / 60.0).round(1)
          }
        end
        render json: { status: 0, data: @data }
      rescue => e
        render json: { status: 1, msg: e.message }
      end
    end
  end

end