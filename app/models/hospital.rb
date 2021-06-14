# encoding: utf-8
class Hospital < ActiveRecord::Base
  has_many :departments, :class_name => 'HospitalDepartment'
  validates_presence_of :name

  LEVEL = %w[三级 三甲 三乙 三丙 二级 二甲 二乙 二丙 一级 一甲 一乙 一丙]
end