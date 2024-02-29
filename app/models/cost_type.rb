# frozen_string_literal: true

class CostType < ApplicationRecord
  validates_presence_of :name, :path
  belongs_to :parent, class_name: self.name, optional: true
  has_many :children, class_name: self.name, foreign_key: :parent_id

  scope :root, -> { where(parent_id: nil, is_parent: true) }

  def to_api
    is_parent ?
      { id: id, name: name, is_parent: is_parent, children: children.order(:id).map(&:to_api) } :
      { id: id, name: name, is_parent: is_parent }
  end

  def has_decendant?(cost_type_id)
    decendant = self.class.find(cost_type_id)
    decendant != self && decendant.ancestor == self
  end

  def ancestor
    parent ? parent.ancestor : self
  end

end