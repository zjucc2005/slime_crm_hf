# frozen_string_literal: true

class CostSummary < ApplicationRecord
  has_many :costs, class_name: 'Cost'
  belongs_to :operator, class_name: 'User', foreign_key: :operator_id
  
  def to_api
    expose_fields(
      :id, :price, :created_at, :updated_at,
      datetime: datetime&.strftime('%F'),
      costs: costs.order(:id).map(&:to_api)
    )
  end

  def update_price!
    self.update!(price: costs.sum(:price))
  end
end