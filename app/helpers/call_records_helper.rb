module CallRecordsHelper

  def call_record_status_badge(category)
    dict = { :pending => 'secondary', :missed => 'warning', :accepted => 'success', :declined => 'danger' }.stringify_keys
    content_tag :span, CallRecord::STATUS[category] || category, :class => "badge badge-#{dict[category] || 'dark' }"
  end

end