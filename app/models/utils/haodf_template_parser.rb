# encoding: utf-8
module Utils
  class HaodfTemplateParser
    # 解析Haodf医生数据导入模板
    # 策略: 1 - 导入时仅回滚报错条目, 2 - 重复导入更新相关信息

    attr_accessor :errors, :row, :created_by, :user_channel_id, :candidate_attr, :work_exp_attrs

    def initialize(row, created_by=nil, user_channel_id=nil)
      @row = row.map(&method(:cell_strip))
      @errors = []
      @created_by = created_by
      @user_channel_id = user_channel_id
      @haodf_id = nil
      @candidate_attr = {}
      @work_exp_attrs = []
      @hospital_attr  = {}
      set_candidate_attr
    end

    # 返回值 true/false
    def import
      if valid?
        # import code
        begin
          ActiveRecord::Base.transaction do
            candidate = Candidate.doctor.where("CAST(property->>'haodf_id' AS INTEGER) = ?", @haodf_id).first
            if candidate
              candidate.update!(
                city:      @candidate_attr[:city],
                title:     @candidate_attr[:title],
                expertise: @candidate_attr[:expertise],
                inquiry:   @candidate_attr[:inquiry]
              )
              if @work_exp_attrs.present?
                work_exp = candidate.experiences.work.first
                work_exp ?
                  work_exp.update!(@work_exp_attrs[0]) :
                  candidate.experiences.work.create!(@work_exp_attrs[0])
              end
            else
              candidate = Candidate.doctor.create!(@candidate_attr)
              candidate.experiences.work.create!(@work_exp_attrs[0]) if @work_exp_attrs.present?
            end

            @hospital = Hospital.where(name: @hospital_attr[:name], province: @hospital_attr[:province]).first
            @hospital ||= Hospital.create!(name: @hospital_attr[:name], province: @hospital_attr[:province], level: @hospital_attr[:level])
            @hospital.departments.find_or_create_by!(name: @hospital_attr[:department])
          end
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
      @haodf_id     = @row[0].to_i  # A, id
      province      = @row[1]       # B, province
      hospital      = @row[2]       # C, hospital
      department    = @row[3]       # D, department
      name          = @row[4]       # E, name
      haodf_url     = @row[5]       # F, url
      title         = @row[6]       # G, title
      edu_title     = @row[7]       # H, educate_title
      expertise     = @row[8]       # I, expertise
      inquiry       = @row[9].to_i  # J, inquiry
      level         = @row[10]      # K, level

      # default setting
      cpt           = 0
      currency      = 'RMB'

      @errors << '姓名不能为空, name is required' if name.blank?
      first_name, last_name = Candidate.name_split(name)

      @candidate_attr = {
        data_source: 'excel', data_channel: 'excel', created_by: @created_by, user_channel_id: @user_channel_id,
        first_name: first_name, last_name: last_name, city: province, title: edu_title, expertise: expertise,
        inquiry: inquiry, cpt: cpt, currency: currency, property: { haodf_id: @haodf_id, haodf_url: haodf_url }
      }

      @work_exp_attrs << {
        org_cn: hospital, department: department, title: title
      }

      @hospital_attr = {
        name: hospital, province: province, level: level, department: department
      }
    end

  end
end