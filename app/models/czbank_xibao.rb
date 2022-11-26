# frozen_string_literal: true

class CzbankXibao < ApplicationRecord
  validates_presence_of :org_name
  validates_numericality_of :sale_value, greater_than_or_equal_to: 0

  before_validation :setup, on: [:create]

  ORG_LIST = %w[三门支行 临海支行 仙居支行 天台支行 温岭支行 玉环支行 路桥支行 黄岩支行 分行业务一部 分行业务二部 分行业务三部 分行业务五部 分行小企业一部 分行市场一部 分行本级中后台 分行营业部]
  TARGET = {
      '分行业务一部' => 600,
      '三门支行' => 5700,
      '玉环支行' => 10500,
      '天台支行' => 8800,
      '临海支行' => 10700,
      '分行小企业一部' => 2800,
      '温岭支行' => 11200,
      '分行营业部' => 9400,
      '仙居支行' => 9900,
      '黄岩支行' => 8800,
      '路桥支行' => 9300,
      '分行市场一部' => 1900,
      '分行业务二部' => 1400,
      '分行业务三部' => 1200,
      '分行业务五部' => 800,
      '分行本级中后台' => 0
  }

  def to_api
    { id: id, org_name: org_name, staff_name: staff_name, sale_value: sale_value, trans_date: trans_date }
  end

  def self.draw_xibao_pic(options={})
    md5_str = Digest::MD5.hexdigest(options.to_json)
    save_file_dir = "public/export/xibao"
    FileUtils.mkdir_p save_file_dir unless File.exist? save_file_dir
    save_file = "#{save_file_dir}/#{md5_str}.jpg"
    # return save_file if File.exists?(save_file) # 如果有历史文件, 则直接返回

    template_path = 'app/javascript/images/xibao_bg.jpg'
    raise 'template not found' unless File.exists? template_path
    template = Magick::Image.read(template_path).first
    full_height = template.rows
    full_width = template.columns
    canvas = Magick::Image.new(full_width, full_height)
    canvas.composite!(template, 0, 0, Magick::CopyCompositeOp) # 铺上模板图层
    text = Magick::Draw.new # 初始化文本格式
    text.font_family = 'Source Han Sans SC'
    puts "SET PARAMS: #{options.to_json}"
    text.annotate(canvas, 0, 0, 240 - options[:org_name].length * 23, 430, options[:org_name]) do
      self.pointsize = 50
      self.fill = '#CD1D1D'
    end
    text.annotate(canvas, 0, 0, 240 - options[:staff_name].length * 23, 500, options[:staff_name]) do
      self.pointsize = 50
      self.fill = '#CD1D1D'
    end
    text.annotate(canvas, 0, 0, 180, 570, options[:trans_date]) do
      self.pointsize = 20
      self.fill = '#FFF9E1'
    end
    text.annotate(canvas, 0, 0, 180, 690, options[:sale_value]) do
      self.pointsize = 70
      self.fill = '#FFF9E1'
    end
    canvas.write(save_file)
    save_file # return
  end

  private
  def setup
    self.staff_id   ||= ''
    self.staff_name ||= ''
    self.trans_date ||= Time.now.to_date
    self.bill_count ||= 1
  end
end