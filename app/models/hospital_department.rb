# encoding: utf-8
class HospitalDepartment < ActiveRecord::Base
  belongs_to :hospital, :class_name => 'Hospital'
  validates_presence_of :name
end