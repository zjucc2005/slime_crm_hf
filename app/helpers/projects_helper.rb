module ProjectsHelper

  def project_options(mode=:default)
    query = case mode
              when :all then Project.all
              else current_user.admin? ? Project.all : current_user.projects
            end
    query = user_channel_filter(query)
    query.where(status: %w[initialized ongoing]).order(:updated_at => :desc).map{|p| [p.project_option_friendly, p.id]}
  end

  # project status display style
  def project_status_badge(status)
    dict = { initialized: 'secondary', ongoing: 'success', finished: 'info', billing: 'warning', billed: 'secondary' }.stringify_keys
    content_tag :span, Project::STATUS[status] || status, :class => "badge badge-#{dict[status] || 'secondary'}"
  end

  def project_requirement_status_badge(status)
    dict = { :ongoing => 'success', :finished => 'secondary', :unfinished => 'danger' }.stringify_keys
    content_tag :span, ProjectRequirement::STATUS[status] || status, :class => "badge badge-#{dict[status] || 'secondary'}"
  end

  def project_task_category_options
    ProjectTask::CATEGORY.to_a.map(&:reverse)
  end

  def project_task_status_options
    ProjectTask::STATUS.select{|k,v| %w[finished cancelled].include?(k)}.to_a.map(&:reverse)
  end

  def project_task_expert_options
    @project.experts.map{|c| [c.uid_name, c.id] }
  end

  def project_task_client_options
    @project.clients.map{|c| [c.uid_name, c.id] }
  end

  def project_task_pm_options
    @project.pm_users.map{|u| [u.uid_name, u.id] }
  end

  def project_task_cost_category_options(project_task)
    ProjectTaskCost::CATEGORY.select do |k, v|
      project_task.costs.where(category: k).count < ProjectTaskCost::CATEGORY_LIMIT[k]
    end.to_a.map(&:reverse)
  end

  def project_task_cost_template_expert_options(project_task)
    project_task.expert.payment_infos.map{|info|
      [ info.to_template, info.id ]
    }
  end

  def project_task_cost_template_recommend_options(project_task)
    recommender = project_task.expert.recommender
    if recommender
      recommender.payment_infos.map{|info|
        [ info.to_template, info.id ]
      }
    else
      []
    end
  end

  def project_export_billing_template_options
    [
      ['对账单', 'settlement_20210604_1'],
      ['定性受访信息表202206 (new)', 'settlement_202206'],
      ['信息表', 'settlement_20230217'],
      ['专家模板', 'settlement_20230516']
    ]
  end

  def project_task_category_badge(category)
    dict = { :interview => 'primary' }.stringify_keys
    content_tag :span, ProjectTask::CATEGORY[category] || category, :class => "badge badge-#{dict[category] || 'secondary'}"
  end

  def project_task_interview_form_badge(category)
    dict = {
      :'face-to-face' => 'secondary',
      :'call'         => 'secondary',
      :'video-call'   => 'secondary',
      :'email'        => 'secondary',
      :'others'       => 'secondary'
    }.stringify_keys
    content_tag :span, ProjectTask::INTERVIEW_FORM[category] || category, :class => "badge badge-#{dict[category] || 'secondary' }"
  end

  def project_task_status_badge(category)
    dict = { :ongoing => 'success', :finished => 'secondary', :cancelled => 'danger' }.stringify_keys
    content_tag :span, ProjectTask::STATUS[category] || category, :class => "badge badge-#{dict[category] || 'secondary' }"
  end

  def project_task_charge_status_badge(category)
    dict = { :paid => 'success', :billed => 'warning', :unbilled => 'danger' }.stringify_keys
    content_tag :span, ProjectTask::CHARGE_STATUS[category] || category, :class => "badge badge-#{dict[category] || 'secondary' }"
  end

  def project_task_payment_status_badge(category)
    dict = { :paid => 'success', :unpaid => 'danger', :free => 'secondary' }.stringify_keys
    content_tag :span, ProjectTask::PAYMENT_STATUS[category] || category, :class => "badge badge-#{dict[category] || 'secondary' }"
  end

  def project_candidate_mark_badge(mark)
    dict = { unsuitable: 'danger', recommended: 'success', interviewed: 'primary', contacting: 'warning', pending: 'secondary', main: 'danger', normal: 'secondary' }.stringify_keys
    content_tag :span, ProjectCandidate::MARK.merge(ProjectCandidate::CLIENT_MARK)[mark] || mark, class: "badge badge-#{dict[mark] || 'dark' }"
  end

end