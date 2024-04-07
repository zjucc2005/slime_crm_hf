# frozen_string_literal: true

class KpiInfo < ApplicationRecord
  belongs_to :kpi_summary, class_name: 'KpiSummary'

  def to_api
    expose_fields(:id, :name, :price, :remark, :created_at, :updated_at)
  end

end