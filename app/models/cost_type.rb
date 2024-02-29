# frozen_string_literal: true

class CostType < ApplicationRecord
  validates_presence_of :name, :path
  belongs_to :parent, class_name: self.name, optional: true
  has_many :children, class_name: self.name, foreign_key: :parent_id

  def to_api
    is_parent ?
      { id: id, name: name, is_parent: is_parent, children: children.order(:id).map(&:to_api) } :
      { id: id, name: name, is_parent: is_parent }
  end

end