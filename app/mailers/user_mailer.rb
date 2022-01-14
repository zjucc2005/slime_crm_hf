class UserMailer < ApplicationMailer
  default from: 'project@hci-consulting.com'

  def test_email
    # @user = params[:user]
    # @url  = 'http://example.com/login'
    mail(
        # from: 'zjucc2005@163.com',
        to: 'zjucc2005@163.com',
        subject: 'Test mail, do not reply'
    )
  end

  # project_task_id - ProjectTask#id
  def project_task_notice_email(project_task_id, category='A')
    @project_task = ProjectTask.find(project_task_id)
    @category = category
    @project = @project_task.project
    @expert = @project_task.expert
    @client = @project_task.client
    to_email = @project_task.client.email
    cc_email = @project.clients.where.not(id: @project_task.client_id).pluck(:email)
    cc_email << @project_task.creator.email
    cc_email << @project_task.pm.email
    subject  = "【hci 专家访谈】 #{@project.code}-#{@project.name}-#{@project_task.expert_level.capitalize} Expert ##{@expert.uid} #{@expert.name}"
    mail(to: to_email, cc: cc_email, subject: subject, from: 'zjucc2005@163.com')
  end

end
