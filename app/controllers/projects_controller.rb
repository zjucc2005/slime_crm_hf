# encoding: utf-8
require 'rubyXL/convenience_methods/cell'
require 'rubyXL/convenience_methods/color'
require 'rubyXL/convenience_methods/font'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'

class ProjectsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  # GET /projects
  def index
    # query = current_user.is_role?('admin') ? Project.all : current_user.projects
    query = params[:my_project] == 'true' ? current_user.projects : Project.all
    query = user_channel_filter(query)
    query = query.where('created_at >= ?', params[:created_at_ge]) if params[:created_at_ge].present?
    query = query.where('created_at <= ?', params[:created_at_le]) if params[:created_at_le].present?
    %w[name code].each do |field|
      query = query.where("#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
    end
    %w[id status user_channel_id].each do |field|
      query = query.where(field.to_sym => params[field]) if params[field].present?
    end
    if params[:company].present?
      query = query.joins(:company).where('companies.name ILIKE :company OR companies.name_abbr ILIKE :company', { company: "%#{params[:company].strip}%" })
    end

    # export excel files
    case params[:commit]
      when 'Weekly update' then export_projects(query.order(:created_at => :desc), category='weekly_update') and return
      else nil
    end

    @projects = query.order(:updated_at => :desc).paginate(:page => params[:page], :per_page => 20)
  end

  # GET /projects/new
  def new
    @project = Project.new
    load_signed_company_options
  end

  # POST /projects
  def create
    begin
      @project = Project.new(project_params.merge(created_by: current_user.id, user_channel_id: current_user.user_channel_id))

      if @project.valid?
        ActiveRecord::Base.transaction do
          @project.save!
          if current_user.is_role?('pm')
            @project.project_users.find_or_create_by!(category: 'pm', user_id: current_user.id)
          end
        end
        flash[:success] = t(:operation_succeeded)
        redirect_to project_path(@project)
      else
        load_signed_company_options
        render :new
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # GET /projects/:id
  def show
    load_project
  end

  # GET /projects/:id/edit
  def edit
    load_project
    load_signed_company_options
  end

  # PUT /projects/:id
  def update
    begin
      load_project

      if @project.update(project_params_update)
        flash[:success] = t(:operation_succeeded)
        redirect_to project_path(@project)
      else
        load_signed_company_options
        render :edit
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # DELETE /projects/:id
  def destroy
    begin
      load_project

      if @project.can_destroy?
        @project.destroy!
        flash[:success] = t(:operation_succeeded)
        redirect_to projects_path
      else
        raise t(:cannot_delete)
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # GET/PUT /projects/add_users
  def add_users
    # if request.put?
    #   begin
    #     @project = Project.find(params[:project_id])
    #     raise t(:not_authorized) unless @project.can_edit?
    #
    #     ActiveRecord::Base.transaction do
    #       # add pm
    #       pm_users = User.where(id: params[:uids], role: 'pm')
    #       pa_users = User.where(id: params[:uids], role: 'pa')
    #       pm_users.each do |user|
    #         @project.project_users.find_or_create_by!(category: user.role, user_id: user.id)
    #       end
    #       # add pa
    #       pa_users.each do |user|
    #         @project.project_users.find_or_create_by!(category: user.role, user_id: user.id)
    #       end
    #     end
    #     flash[:success] = t(:operation_succeeded)
    #     redirect_to project_path(@project)
    #   rescue Exception => e
    #     flash[:error] = e.message
    #     redirect_to projects_path
    #   end
    # end

    begin
      @project = Project.find(params[:project_id])
      raise t(:not_authorized) unless @project.can_edit?

      ActiveRecord::Base.transaction do
        # add pm
        pm_users = User.where(id: params[:uids], role: 'pm')
        pa_users = User.where(id: params[:uids], role: 'pa')
        pm_users.each do |user|
          @project.project_users.find_or_create_by!(category: user.role, user_id: user.id)
        end
        # add pa
        pa_users.each do |user|
          @project.project_users.find_or_create_by!(category: user.role, user_id: user.id)
        end
      end
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # GET/PUT /projects/add_experts.js
  def add_experts
    # if request.put?
    #   begin
    #     @project = Project.find(params[:project_id])
    #     raise t(:not_authorized) unless @project.can_edit?
    #
    #     ActiveRecord::Base.transaction do
    #       (params[:uids] || []).each do |candidate_id|
    #         @project.project_candidates.expert.find_or_create_by!(candidate_id: candidate_id)
    #       end
    #     end
    #     flash[:success] = t(:operation_succeeded)
    #     if params[:commit] == t('action.submit_and_continue_to_add')
    #       redirect_to candidates_path(from_source: 'project', project_id: @project.id)
    #     else
    #       redirect_to project_path(@project)
    #     end
    #   rescue Exception => e
    #     flash[:error] = e.message
    #     redirect_to projects_path
    #   end
    # end

    begin
      @project = Project.find(params[:project_id])
      raise t(:not_authorized) unless @project.can_edit?

      ActiveRecord::Base.transaction do
        (params[:uids] || []).each do |candidate_id|
          @project.project_candidates.expert.find_or_create_by!(candidate_id: candidate_id)
        end
      end
      @notice = t(:operation_succeeded)

      if params[:mode] == '0'
        flash[:success] = t(:operation_succeeded)
        redirect_to project_path(@project)
      end
    rescue Exception => e
      @notice = e.message
    end

    respond_to do |f|
      f.js
      f.html
    end
  end

  # GET/PUT /projects/:id/add_clients
  def add_clients
    begin
      load_project
      query = @project.company.candidates
      %w[name nickname title phone email].each do |field|
        query = query.where("#{field} ILIKE ?", "%#{params[field].strip}%") if params[field].present?
      end
      @clients = query.order(:created_at => :desc)

      if request.put?
        raise t(:not_authorized) unless @project.can_edit?

        ActiveRecord::Base.transaction do
          @project.project_candidates.client.destroy_all
          (params[:uids] || []).each do |candidate_id|
            @project.project_candidates.client.create!(candidate_id: candidate_id)
          end
        end
        flash[:success] = t(:operation_succeeded)
        redirect_to project_path(@project)
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # GET/PUT /projects/:id/add_project_task
  def add_project_task
    begin
      load_project
      @project_task = @project.project_tasks.new(expert_id: params[:expert_id])

      if request.put?
        raise t(:not_authorized) unless @project.can_add_task?
        @project_task = ProjectTask.new(project_task_params.merge(project_id: @project.id,
                                                                  created_by: current_user.id,
                                                                  user_channel_id: current_user.user_channel_id))
        if @project_task.save
          flash[:success] = t(:operation_succeeded)
          redirect_with_return_to(project_path(@project))
        else
          render :add_project_task
        end
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # GET/PUT /projects/:id/add_project_requirement
  def add_project_requirement
    begin
      load_project
      @project_requirement = @project.project_requirements.new

      if request.put?
        raise t(:not_authorized) unless @project.can_add_requirement?

        # @project_requirement = @project.project_requirements.new(project_requirement_params.to_h.merge(created_by: current_user.id))
        @project_requirement = ProjectRequirement.new(project_requirement_params.merge(project_id: @project.id, created_by: current_user.id))
        if @project_requirement.save
          flash[:success] = t(:operation_succeeded)
          redirect_to project_path(@project)
        else
          render :add_project_requirement
        end
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # DELETE /projects/:id/delete_user?user_id=1
  def delete_user
    begin
      load_project
      raise t(:not_authorized) unless @project.can_edit?
      @project.project_users.find_by(user_id: params[:user_id]).destroy
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # DELETE /projects/:id/delete_expert?expert_id=1
  def delete_expert
    begin
      load_project
      raise t(:not_authorized) unless @project.can_edit?
      @project.project_candidates.find_by(candidate_id: params[:expert_id]).destroy
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # DELETE /projects/:id/delete_client?client_id=1
  def delete_client
    begin
      load_project
      raise t(:not_authorized) unless @project.can_edit?
      @project.project_candidates.find_by(candidate_id: params[:client_id]).destroy
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # PUT /project/:id/start
  def start
    begin
      load_project
      raise t(:not_authorized) unless @project.can_start?
      @project.start!
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # PUT /projects/:id/close
  def close
    begin
      load_project
      raise t(:not_authorized) unless @project.can_close?
      @project.close!
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # PUT /projects/:id/reopen
  def reopen
    begin
      load_project
      raise t(:not_authorized) unless @project.can_reopen?
      @project.reopen!
      flash[:success] = t(:operation_succeeded)
      redirect_to project_path(@project)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to projects_path
    end
  end

  # GET /projects/:id/experts
  def experts
    load_project
    query = @project.experts
    @experts = query.paginate(:page => params[:page], :per_page => 100)
  end

  # GET /projects/:id/project_tasks
  def project_tasks
    load_project
    query = @project.project_tasks
    @project_tasks = query.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 20)
  end

  # GET /projects/:id/user_options.json
  def user_options
    load_project
    users = @project.users
    render :json => users.map{|user| [user.uid_name , user.id] }
  end

  # POST /projects/:id/export_billing_excel?template=1&close_or_not=false
  def export_billing_excel
    load_project
    begin
      case params[:template]
        when 'settlement_20210604_1' then export_settlement_20210604_1(@project)
        when 'settlement_20210604_2' then export_settlement_20210604_2(@project)
        when 'iqvia_settlement'      then export_iqvia_settlement_template(@project)
        else raise('params error')
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to project_path(@project)
    end
  end

  private
  def load_project
    @project = Project.find(params[:id])
    @can_operate = @project.can_be_operated_by(current_user)
  end

  def project_params
    params.require(:project).permit(:company_id, :name, :code, :industry)
  end

  def project_params_update
    params.require(:project).permit(:name, :code, :industry, :requirement, :started_at, :ended_at)
  end

  def project_task_params
    params.require(:project_task).permit(:category, :expert_id, :client_id, :pm_id, :interview_form, :started_at, :expert_level, :expert_rate)
  end

  def project_requirement_params
    params.require(:project_requirement).permit(:content, :demand_number, :file, :operator_id)
  end

  # 加载客户公司
  def load_signed_company_options
    @signed_company_options = user_channel_filter(Company.signed).pluck(:name, :id)
  end

  # 导出项目信息
  def export_projects(query, category)
    query_limit = 1000  # export data limit
    if query.count > query_limit
      flash[:error] = "导出数据条目过多, 当前: #{query.count}, 最大: #{query_limit}"
      redirect_to projects_path and return
    end

    template_path = case category
                      when 'weekly_update' then 'public/templates/project_weekly_update_template.xlsx'
                      else ''
                    end

    raise 'template file not found' unless File.exist?(template_path)
    book = ::RubyXL::Parser.parse(template_path)                      # read from template file
    sheet = book[0]

    case category
      when 'weekly_update' then set_sheet_weekly_update(sheet, query)
      else raise("invalid category[#{category}]")
    end

    file_dir = "public/export/#{Time.now.strftime('%y%m%d')}"
    FileUtils.mkdir_p file_dir unless File.exist? file_dir
    file_path = "#{file_dir}/projects_#{category}_#{current_user.id}_#{Time.now.strftime('%H%M%S')}.xlsx"
    book.write file_path
    send_file file_path
  end

  def set_sheet_weekly_update(sheet, query)
    current_week = Time.now.beginning_of_week
    row = 1
    query.each do |project|
      if project.created_at >= current_week
        project_phase = 'New'
      elsif project.updated_at < Time.now - 1.week  # 1周内未更新的项目
        project_phase = 'Pending'
      else
        project_phase = 'On-going'
      end
      current_week_task_count = project.project_tasks.where(status: 'finished').where('started_at >= ?', current_week).count
      last_week_task_count = project.project_tasks.where(status: 'finished').where('started_at >= ? AND started_at < ?', current_week - 1.week, current_week).count

      sheet.add_cell(row, 0, project.code)                                      # 项目号/项目代码
      sheet.add_cell(row, 1, project.name)                                      # 项目名称
      sheet.add_cell(row, 2, project.created_at.strftime('%F'))                 # 收到项目日期/创建日期
      sheet.add_cell(row, 3, project_phase)                                     # 项目阶段 [new/on-going/pending]
      sheet.add_cell(row, 4, project.project_requirements.sum(:demand_number))  # 计划出Call/项目需求总人数
      sheet.add_cell(row, 5, last_week_task_count)                              # 上周出Call / 上周完成任务
      sheet.add_cell(row, 6, current_week_task_count)                           # 本周出Call / 本周完成任务数
      sheet.add_cell(row, 7, '')                                                # 下周预计出Call
      sheet.add_cell(row, 8, '')                                                # 备注
      row += 1
    end

    sheet.add_cell(row, 3, '小计')
    sheet.add_cell(row, 4, '', "SUM(E2:E#{row})")
    sheet.add_cell(row, 5, '', "SUM(F2:F#{row})")
  end

  def export_iqvia_settlement_template(project)
    template_path = 'public/templates/iqvia_settlement_template.xlsx'
    raise 'template file not found' unless File.exist?(template_path)
    query = project.project_tasks.where(status: 'finished').order(:started_at => :asc)
    raise 'project task not found' if query.count == 0

    color1 = '000080' # 主色调, 普蓝
    color2 = 'CCCCFF' # 辅色调, 浅蓝
    bottom_text = '备注:关于本执行单的最终解释权归IQVIA。如有更新版本，以更新版为准。'
    book = ::RubyXL::Parser.parse(template_path)  # read from template file
    sheet = book[0]
    sheet.add_cell(3, 1, project.code)  # B4, 项目内部号
    sheet.sheet_data[3][1].change_horizontal_alignment('left')  # B4 align to left
    sheet.add_cell(4, 1, query.first.started_at.try(:strftime, '%F') )  # B5, 订单下达日期

    row = 11  # 任务表格起始行
    query.each_with_index do |task, index|
      # 内容填充 >> code here
      exp = task.expert.latest_work_experience

      sheet.add_cell(row, 0,  index + 1)                             # 代理编号
      sheet.add_cell(row, 1,  '海鄞')                                # 公司名称
      if exp
        sheet.add_cell(row, 2,  "#{exp.org_cn}#{exp.title}")         # 配额描述
      else
        sheet.add_cell(row, 2, '')
      end
      sheet.add_cell(row, 3,  '全国')                                # 城市
      sheet.add_cell(row, 4,  1)                                     # 预计样本量
      sheet.add_cell(row, 5,  1)                                     # 实际样本量
      sheet.add_cell(row, 6,  '')                                    # 咨询服务费单价
      sheet.add_cell(row, 7,  (2500 * task.expert_rate).round(2) )   # 执行/招募单价
      sheet.add_cell(row, 8,  '')                                    # 其他费用单价
      sheet.add_cell(row, 9,  (2500 * task.expert_rate).round(2) )   # 预计订单折前总额
      sheet.add_cell(row, 10, (2100 * task.expert_rate).round(2) )   # 预计订单折后总额
      sheet.add_cell(row, 11, (task.actual_price / 0.84).round(2) )  # 实际结算折前总额
      sheet.add_cell(row, 12, task.actual_price)                     # 实际结算折后总额
      if task.memo.present?
        sheet.add_cell(row, 13, "#{task.duration}分钟, #{task.memo}")  # 备注, 实际时长 + 备注
      else
        sheet.add_cell(row, 13, "#{task.duration}分钟")
      end

      # 格式设定
      sheet.sheet_data[row][0].change_horizontal_alignment('center')
      (0..13).each {|i|
        sheet[row][i].change_border(:bottom, :thin)
        sheet[row][i].change_border(:right, :thin)
        sheet[row][i].change_border_color(:bottom, color1)
        sheet[row][i].change_border_color(:right, color1)
      }
      (4..8).each {|i| sheet[row][i].change_fill(color2) }

      row += 1
      sheet.insert_row(row)
    end

    # merge cells
    sheet.merge_cells(11, 1, row - 1, 1)

    # sum
    sheet.add_cell(row + 1, 9,  '', "SUM(J12:J#{row})")
    sheet.add_cell(row + 1, 10, '', "SUM(K12:K#{row})")
    sheet.add_cell(row + 1, 11, '', "SUM(L12:L#{row})")
    sheet.add_cell(row + 1, 12, '', "SUM(M12:M#{row})")
    (9..12).each {|i|
      sheet[row + 1][i].change_fill(color1)          # 补背景色
      sheet[row + 1][i].change_font_color('FFFFFF')  # 白色字体
    }

    # bottom cell
    sheet.add_cell(row + 3, 0, bottom_text)
    sheet[row + 3][0].change_horizontal_alignment('left')
    sheet[row + 3][0].change_font_bold(true)

    ActiveRecord::Base.transaction do
      query.each do |task|
        task.update(charge_status: 'billed') if task.charge_status == 'unbilled'  # 自动更新收费状态
      end
      project.close! if params[:close_or_not] == 'true'  # 关闭项目选项
    end

    file_dir = "public/export/#{Time.now.strftime('%y%m%d')}"
    FileUtils.mkdir_p file_dir unless File.exist? file_dir
    file_path = "#{file_dir}/#{project.code}_IQVIA项目执行订单-海鄞.xlsx"
    book.write file_path
    send_file file_path
  end

  def export_settlement_20210604_1(project)
    template_path = 'public/templates/settlement_template_20210604_1.xlsx'
    raise 'template file not found' unless File.exist?(template_path)
    query = project.project_tasks.where(status: 'finished').order(:started_at => :asc)
    raise 'project task not found' if query.count == 0

    book = ::RubyXL::Parser.parse(template_path)  # read from template file
    sheet = book[0]
    sheet.add_cell(0, 1, query.count)  # B1, 访谈个数

    query.each_with_index do |task, index|
      row = index + 2
      sheet.add_cell(row, 0, task.project.name)                                               # A, 项目名称
      sheet.add_cell(row, 1, task.project.code)                                               # B, 项目号
      sheet.add_cell(row, 2, '')                                                              # C, 访谈人
      sheet.add_cell(row, 3, ProjectTask::INTERVIEW_FORM[task.interview_form])                # D, 访问类型
      sheet.add_cell(row, 4, "# #{task.expert.uid}")                                          # E, 专家编号
      sheet.add_cell(row, 5, task.expert.mr_name)                                             # F, 专家称呼
      exp = task.expert.latest_work_experience
      exp ? sheet.add_cell(row, 6, "#{exp.org_cn}#{exp.title}") : sheet.add_cell(row, 6, '')  # G, 专家信息
      sheet.add_cell(row, 7, (task.started_at.strftime('%F') rescue ''))                      # H, 访谈日期
      sheet.add_cell(row, 8, (task.started_at.strftime('%H:%M') rescue ''))                   # I, 开始时间
      sheet.add_cell(row, 9, (task.ended_at.strftime('%H:%M') rescue '' ))                    # J, 结束时间
      sheet.add_cell(row, 10, task.duration)                                                  # K, 访谈时长
      sheet.add_cell(row, 11, task.charge_duration)                                           # L, 收费时长
      sheet.add_cell(row, 12, (2500 * task.expert_rate).round(2))                             # M, 访谈单价
      sheet.add_cell(row, 13, (task.actual_price / 0.84).round(2))                            # N, 折前费用
      sheet.add_cell(row, 14, task.actual_price)                                              # O, 折后费用
      sheet.add_cell(row, 15, task.costs.where(category: 'expert').sum(:price))               # P, 礼金费用
    end

    ActiveRecord::Base.transaction do
      query.each do |task|
        task.update(charge_status: 'billed') if task.charge_status == 'unbilled'  # 自动更新收费状态
      end
      project.close! if params[:close_or_not] == 'true'  # 关闭项目选项
    end

    file_dir = "public/export/#{Time.now.strftime('%y%m%d')}"
    FileUtils.mkdir_p file_dir unless File.exist? file_dir
    file_path = "#{file_dir}/#{project.code}_财务模板1.xlsx"
    book.write file_path
    send_file file_path
  end

  def export_settlement_20210604_2(project)
    template_path = 'public/templates/settlement_template_20210604_2.xlsx'
    raise 'template file not found' unless File.exist?(template_path)
    query = project.project_tasks.where(status: 'finished').order(:started_at => :asc)
    raise 'project task not found' if query.count == 0

    book = ::RubyXL::Parser.parse(template_path)  # read from template file
    sheet = book[0]

    query.each_with_index do |task, index|
      row = index + 2
      sheet.add_cell(row, 0, task.project.code)                                               # A, 内部项目号
      sheet.add_cell(row, 1, index + 1)                                                       # B, 序号
      sheet.add_cell(row, 2, '全国')                                                          # C, 城市
      sheet.add_cell(row, 3, '')                                                              # D
      sheet.add_cell(row, 4, '')                                                              # E
      sheet.add_cell(row, 5, '')                                                              # F
      sheet.add_cell(row, 6, 'IDI（包括面对面深访及电话深访）')                                  # G
      sheet.add_cell(row, 7, '')                                                              # H
      exp = task.expert.latest_work_experience
      exp ? sheet.add_cell(row, 8, "#{exp.org_cn}#{exp.title}") : sheet.add_cell(row, 8, '')  # I, 医院
      sheet.add_cell(row, 9, '')                                                              # J, 医院级别
      sheet.add_cell(row, 10, '')                                                             # K, 科室
      sheet.add_cell(row, 11, task.expert.mr_name)                                            # L, 医生姓名
      sheet.add_cell(row, 12, '')                                                             # M, 职称
      sheet.add_cell(row, 13, '')                                                             # N, 医生座机
      sheet.add_cell(row, 14, '')                                                             # O, 医生手机号码
      sheet.add_cell(row, 15, (task.started_at.strftime('%F') rescue '') )                    # P, 访问日期
      sheet.add_cell(row, 16, (task.started_at.strftime('%H:%M') rescue ''))                  # Q, 访问时间
      sheet.add_cell(row, 17, '')                                                             # R, 访问地点
      sheet.add_cell(row, 18, '')                                                             # S, 礼金支付方
      sheet.add_cell(row, 19, task.costs.where(category: 'expert').sum(:price))               # T, 礼金支付数额
      sheet.add_cell(row, 20, '银行卡转帐（公对私）')                                           # U, 礼金支付方式
      sheet.add_cell(row, 21, '')                                                             # V
    end

    ActiveRecord::Base.transaction do
      query.each do |task|
        task.update(charge_status: 'billed') if task.charge_status == 'unbilled'  # 自动更新收费状态
      end
      project.close! if params[:close_or_not] == 'true'  # 关闭项目选项
    end

    file_dir = "public/export/#{Time.now.strftime('%y%m%d')}"
    FileUtils.mkdir_p file_dir unless File.exist? file_dir
    file_path = "#{file_dir}/#{project.code}_定性受访信息表.xlsx"
    book.write file_path
    send_file file_path
  end

end