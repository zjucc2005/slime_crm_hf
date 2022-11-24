# frozen_string_literal: true

module Utils
  class CzbankXibaoTemplateParser
    # 解析通话记录导入模板

    attr_accessor :errors, :row, :instance_attr

    def initialize(row)
      @row = row.map(&method(:cell_strip))
      @errors = []
      @instance_attr = {}
      set_instance_attr
    end

    # 返回值 true/false
    def import
      if valid?
        # import code
        begin
          if @instance_attr[:cod_id].present?
            instance = CzbankXibao.where(cod_id: @instance_attr[:cod_id]).first
            if instance
              instance.update!(@instance_attr)
            else
              CzbankXibao.create!(@instance_attr)
            end
          else
            instance = CzbankXibao.where(org_name: @instance_attr[:org_name], staff_name: @instance_attr[:staff_name],
                                         trans_date: @instance_attr[:trans_date], sale_value: @instance_attr[:sale_value]).first
            if instance.nil?
              CzbankXibao.create!(@instance_attr)
            end
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

    def set_instance_attr
      cod_id     = @row[1]
      trans_date = @row[10].present? ? @row[10] : nil
      staff_id   = (@row[20].present? && @row[20] != '#N/A') ? @row[20].to_s.upcase : @row[17].to_s.upcase
      staff_name = @row[21].present? ? @row[21] : ''
      org_name   = @row[22] == '分行本级' ? '分行本级中后台' : @row[22]
      sale_value = @row[23]
      bill_count = @row[24]

      @instance_attr = {
          cod_id: cod_id, trans_date: trans_date, staff_id: staff_id, staff_name: staff_name, org_name: org_name,
          sale_value: sale_value, bill_count: bill_count
      }
    end

    private
    def cell_strip(cell)
      String === cell ? cell.strip : cell
    end
  end
end