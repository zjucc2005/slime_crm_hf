# encoding: utf-8
module Utils
  class ClientTemplateParser
    # 解析客户Seat导入模板

    attr_accessor :errors, :row, :created_by, :user_channel_id, :candidate_attr

    def initialize(row, company, created_by=nil, user_channel_id=nil)
      @row = row.map(&method(:cell_strip))
      @errors = []
      @company = company  # Company 实例
      @created_by = created_by
      @user_channel_id = user_channel_id
      @candidate_attr = {}
      set_candidate_attr
    end

    # 返回值 true/false
    def import
      if valid?
        # import code
        begin
          # ActiveRecord::Base.transaction do
            @company.candidates.client.create!(@candidate_attr)
          # end
          true  # return
        rescue Exception => e
          @errors << e.message
          false # return
        end
      else
        false # return
      end
    end

    # 返回值 true/false
    def valid?
      @errors.empty?
    end

    private
    def cell_strip(cell)
      String === cell ? cell.strip : cell
    end

    def set_candidate_attr
      last_name     = @row[0].to_s
      first_name    = @row[1].to_s
      nickname      = @row[2].to_s
      phone         = @row[3]
      email         = @row[4]
      title         = @row[5]

      # validates_presence_of - last_name, email
      @errors << '姓不能为空' if last_name.blank?
      if phone.present? && Candidate.client.exists?(phone: phone)
        @errors << '电话已被使用'
      end
      @errors << '邮箱不能为空' if email.blank?
      @errors << '重复导入' if Candidate.client.exists?(last_name: last_name, first_name: first_name, email: email)

      @candidate_attr = {
        data_source: 'excel', data_channel: 'excel', created_by: @created_by, user_channel_id: @user_channel_id,
        first_name: first_name, last_name: last_name, nickname: nickname, phone: phone, email: email, title: title,
        cpt: 0
      }
    end

  end
end