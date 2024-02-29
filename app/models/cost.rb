# frozen_string_literal: true

class Cost < ApplicationRecord
  belongs_to :cost_summary, class_name: 'CostSummary'
  
  def to_api
    expose_fields(:id, :cost_type_id, :name, :price, :created_at, :updated_at)
  end

end