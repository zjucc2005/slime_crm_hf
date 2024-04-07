# frozen_string_literal: true

class KpiSummary < ApplicationRecord
  belongs_to :user, class_name: 'User'
  has_many :kpi_infos, class_name: 'KpiInfo', dependent: :destroy

  def to_api
    expose_fields(
      :id, :created_at, :updated_at,
      user: user&.to_api,
      datetime: datetime&.strftime('%F'),
      kpi_infos: kpi_infos.order(:id).map(&:to_api)
    )
  end

end