# encoding: utf-8
class Hospital < ApplicationRecord
  has_many :departments, class_name: 'HospitalDepartment', dependent: :destroy
  validates_presence_of :name
  before_validation :setup, on: [:create, :update]

  LEVEL = %w[三级 三甲 三乙 三丙 二级 二甲 二乙 二丙 一级 一甲 一乙 一丙]
  MAX_KWLIST_LENGTH = 5

  private
  def setup
    if self.kwlist.is_a? String
      self.kwlist = self.kwlist.split(',').map(&:strip)
      if self.kwlist.length > MAX_KWLIST_LENGTH
        errors.add(:kwlist, :less_than_or_equal_to, count: MAX_KWLIST_LENGTH)
      end
    else
      errors.add(:kwlist, :invalid_format)
    end
  end
end